resource "aws_db_subnet_group" "main" {
  name          = "${var.env_name}-db-subnet-group"
  description   = "Subnet group for ${var.env_name} RDS instance"
  subnet id     = var.private_subnet_ids
  tags = {
    Name        = "${var.env_name}-db-subnet-group"
    Environment = var.env_name
  }
}


resource "aws_db_instance" "main" {
 identifier = "${var.env_name}-postgres-db"
  engine         = "postgres"
  engine_version = "15"           
  instance_class = "db.t3.micro"  
  allocated_storage     = 20     
  storage_type          = "gp2"   
  storage_encrypted     = true    
  db_name  = "appdb"              
  username = var.db_username
  password = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible = false

  backup_retention_period = 7    
  skip_final_snapshot     = true  
  
  auto_minor_version_upgrade = true
  tags = {
    Name        = "${var.env_name}-postgres-db"
    Environment = var.env_name
  }
}
