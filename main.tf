# Find the VPC and Availability Zone of the GPN subnet.
data "aws_subnet" "gpn" {
  id = var.subnet_id
}

# Read the EBR subnet only when EBR is enabled.
data "aws_subnet" "ebr" {
  count = var.network_interfaces.enable_ebr ? 1 : 0
  id    = var.ebr_subnet_id
}

# data "aws_ami" "selected" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = [var.ami_config.name]
#   }
#   owners = var.ami_config.owner_accounts
# }

# Security group used by the GPN NIC.
resource "aws_security_group" "gpn" {
  name_prefix = "${var.environment}-${var.app_tier}-gpn-"
  description = "GPN security group for ${var.environment}"
  vpc_id      = data.aws_subnet.gpn.vpc_id

  dynamic "ingress" {
    for_each = var.gpn_ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.gpn_egress_rules

    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.app_tier}-gpn-sg"
      NetworkType = "GPN"
    }
  )
}

# Security group used by the EBR NIC.
# This security group is created only when EBR is enabled.
resource "aws_security_group" "ebr" {
  count = var.network_interfaces.enable_ebr ? 1 : 0

  name_prefix = "${var.environment}-${var.app_tier}-ebr-"
  description = "EBR security group for ${var.environment}"
  vpc_id      = data.aws_subnet.ebr[0].vpc_id

  dynamic "ingress" {
    for_each = var.ebr_ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.ebr_egress_rules

    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.app_tier}-ebr-sg"
      NetworkType = "EBR"
    }
  )
}

# One GPN NIC is created for every EC2 instance.
resource "aws_network_interface" "gpn" {
  count = var.instance_count

  subnet_id = var.subnet_id

  # security_groups = concat(
  #   [aws_security_group.gpn.id],
  #   var.security_group_ids
  # )

  tags = merge(
    var.tags,
    {
      Name = format(
        "%s-%s-%02d-gpn-nic",
        var.environment,
        var.app_tier,
        count.index + 1
      )

      NetworkType = "GPN"
    }
  )
}

# One EBR NIC is created for every EC2 instance only when enabled.
resource "aws_network_interface" "ebr" {
  count = var.network_interfaces.enable_ebr ? var.instance_count : 0

  subnet_id = var.ebr_subnet_id

  # security_groups = concat(
  #   [aws_security_group.ebr[0].id],
  #   var.security_group_ids
  # )

  tags = merge(
    var.tags,
    {
      Name = format(
        "%s-%s-%02d-ebr-nic",
        var.environment,
        var.app_tier,
        count.index + 1
      )

      NetworkType = "EBR"
    }
  )
}

resource "aws_network_interface" "nas" {
  count     = var.network_interfaces.enable_nas ? var.instance_count : 0
  subnet_id = var.nas_subnet_id
  # security_groups = concat(
  #   [aws_security_group.gpn.id],
  #   var.security_group_ids
  # )

  tags = merge(
    var.tags,
    {
      Name = format(
        "%s-%s-%02d-nas-nic",
        var.environment,
        var.app_tier,
        count.index + 1
      )
    }
  )

}

# Create the EC2 instances.
resource "aws_instance" "server" {
  count = var.instance_count
  ami   = var.ami_id
  # ami           = data.aws_ami.selected.id
  instance_type = var.instance_type

  # Device index 0 makes GPN the primary NIC.
  network_interface {
    network_interface_id = aws_network_interface.gpn[count.index].id
    device_index         = 0
  }

  # Device index 1 adds EBR as the secondary NIC.
  # This block is skipped when ebr_enabled is false.
  dynamic "network_interface" {
    for_each = var.network_interfaces.enable_ebr ? [1] : []

    content {
      network_interface_id = aws_network_interface.ebr[count.index].id
      device_index         = 1
    }
  }


  dynamic "network_interface" {
    for_each = var.network_interfaces.enable_nas ? [2] : []
    content {
      network_interface_id = aws_network_interface.nas[count.index].id
      device_index         = 2
    }
  }
  root_block_device {
    volume_size           = var.root_volume.size
    volume_type           = var.root_volume.type
    encrypted             = true
    delete_on_termination = true


    tags = merge(
      var.tags,
      {
        Name = format(
          "%s-%s-%02d-root",
          var.environment,
          var.app_tier,
          count.index + 1
        )
      }
    )
  }

  
  tags = merge(
    var.tags,
    {
      Name = format(
        "%s-%s-%02d",
        var.environment,
        var.app_tier,
        count.index + 1
      )

      ApplicationTier = var.app_tier
      EBREnabled      = tostring(var.network_interfaces.enable_ebr)
      ManagedBy       = "Terraform"
    }
  )

  lifecycle {

  precondition {
    condition = (
      var.network_interfaces.enable_ebr == false ||
      var.ebr_subnet_id != null
    )

    error_message = "ebr_subnet_id must be provided when EBR is enabled."
  }

  precondition {
    condition = (
      var.network_interfaces.enable_ebr == false ||
      data.aws_subnet.gpn.availability_zone ==
      data.aws_subnet.ebr[0].availability_zone
    )

    error_message = "GPN and EBR subnets must be in same AZ."
  }

}
}


