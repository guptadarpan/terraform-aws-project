output "bastion_public_ip" {
  description = "The public IP of the bastion host — use this to SSH in"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "The instance ID of the bastion host"
  value       = aws_instance.bastion.id
}
