output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.server[*].id
}

output "private_ip" {
  description = "Primary private IP addresses from the GPN NICs"
  value       = aws_network_interface.gpn[*].private_ip
}

output "gpn_network_interface_ids" {
  description = "IDs of the GPN network interfaces"
  value       = aws_network_interface.gpn[*].id
}

output "ebr_network_interface_ids" {
  description = "IDs of the EBR network interfaces"
  value       = aws_network_interface.ebr[*].id
}

output "gpn_security_group_id" {
  description = "Security group created for GPN"
  value       = aws_security_group.gpn.id
}

output "ebr_security_group_id" {
  description = "Security group created for EBR"
  value = (
    var.ebr_enabled
    ? aws_security_group.ebr[0].id
    : null
  )
}