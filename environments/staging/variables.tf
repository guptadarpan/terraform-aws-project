variable "env_name" {
  description = "Name of the environment"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the whole VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "IP range for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "IP range for the first private subnet"
  type        = string
}

variable "private_subnet_cidr_2" {
  description = "IP range for the second private subnet"
  type        = string
}

variable "availability_zone" {
  description = "Primary availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Secondary availability zone for RDS"
  type        = string
  default     = "us-east-1b"
}

variable "ami_id" {
  description = "Amazon Machine Image ID for the bastion EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address — restricts SSH access to just you"
  type        = string
}

variable "db_username" {
  description = "Master username for the Postgres database"
  type        = string
}

variable "db_password" {
  description = "Master password for the Postgres database"
  type        = string
  sensitive   = true  
