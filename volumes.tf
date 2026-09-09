locals {

  ebs_volumes = flatten([
    for instance_index in range(var.instance_count) : [
      for volume in var.additional_ebs_volumes : {
        instance_index = instance_index
        device_name    = volume.device_name
        volume_size    = volume.volume_size
        volume_type = volume.type
        encrypted = volume.encrypted
        throughput = volume.throughput
        key            = "${instance_index}-${volume.device_name}"
      }

    ]

  ])

}

resource "aws_ebs_volume" "data" {
  for_each = {
    for volume in local.ebs_volumes :
    volume.key => volume
  }

  availability_zone = data.aws_subnet.gpn.availability_zone
  size              = each.value.volume_size
  #encrypted         = true
  type = each.value.volume_type
  encrypted = each.value.encrypted
  throughput = (each.value.volume_type == "gp3"? each.value.throughput: null)

  tags = merge(
    var.tags,
    {
      Name = format(
        "%s-%s-data",
        var.environment,
        var.app_tier
      )
    }
  )

}

resource "aws_volume_attachment" "data" {
  for_each = {
    for volume in local.ebs_volumes :
    volume.key => volume
  }

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.data[each.key].id
  instance_id = aws_instance.server[each.value.instance_index].id

}
