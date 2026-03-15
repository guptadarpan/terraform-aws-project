variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "db_username" {
  description = "Master username for Postgres"
  type        = string
}

variable "db_password" {
  description = "Master password for Postgres"
  type        = string
  sensitive   = true  # hides this value from all terminal output
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)  # a list because AWS needs at least 2
}

variable "rds_sg_id" {
  description = "Security group ID for RDS — comes from vpc module output"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}
