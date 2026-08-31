variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "AMI ID used to create the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "app_tier" {
  description = "Application tier, for example web, app, or db"
  type        = string
  default     = "app"
}

variable "subnet_id" {
  description = "GPN subnet ID"
  type        = string
}

variable "ebr_enabled" {
  description = "Enable or disable the EBR network interface"
  type        = bool
  default     = false
}

variable "ebr_subnet_id" {
  description = "EBR subnet ID, required when EBR is enabled"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 50
}

variable "additional_ebs_volumes" {
  description = "Additional EBS volumes attached to every instance"

  type = list(object({
    device_name = string
    volume_size = number
  }))

  default = []
}

variable "security_group_ids" {
  description = "Existing security group IDs attached to both GPN and EBR NICs"
  type        = list(string)
  default     = []
}

variable "gpn_ingress_rules" {
  description = "Custom inbound rules for the GPN security group"

  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = []
}

variable "gpn_egress_rules" {
  description = "Custom outbound rules for the GPN security group"

  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "ebr_ingress_rules" {
  description = "Custom inbound rules for the EBR security group"

  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = []
}

variable "ebr_egress_rules" {
  description = "Custom outbound rules for the EBR security group"

  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "tags" {
  description = "Additional tags applied to the resources"
  type        = map(string)
  default     = {}
}