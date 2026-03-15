variable "env_name" {
  description = "Environment name e.g. staging or production"
  type        = string
}

variable "ami_id" {
  description = "Amazon Machine Image ID — the OS for the server"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet — comes from vpc module output"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for bastion — comes from vpc module output"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair created in AWS"
  type        = string
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC — comes from vpc module output"
  type        = string
}
