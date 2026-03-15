variable "env_name" {
  description = "Environment name e.g. staging or production"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the VPC e.g. 10.0.0.0/16"
  type        = string
}

variable "public_subnet_cidr" {
  description = "IP range for the public subnet e.g. 10.0.1.0/24"
  type        = string
}

variable "private_subnet_cidr" {
  description = "IP range for the private subnet e.g. 10.0.2.0/24"
  type        = string
}

variable "availability_zone" {
  description = "AWS availability zone e.g. us-east-1a"
  type        = string
  default     = "us-east-1a"
}

variable "my_ip" {
  description = "Your public IP address — used to restrict SSH access"
  type        = string
}
