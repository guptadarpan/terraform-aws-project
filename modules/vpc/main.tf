resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true  
  enable_dns_hostnames = true   
  tags = {
    Name        = "${var.env_name}-vpc"
    Environment = var.env_name
  }
}


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true  
  tags = {
    Name        = "${var.env_name}-public-subnet"
    Environment = var.env_name
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.env_name}-private-subnet"
    Environment = var.env_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.env_name}-igw"
    Environment = var.env_name
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                  
    gateway_id = aws_internet_gateway.igw.id   
  }

  tags = {
    Name        = "${var.env_name}-public-rt"
    Environment = var.env_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.env_name}-private-rt"
    Environment = var.env_name
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.env_name}-bastion-sg"
  description = "Allow SSH only from admin IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from admin IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # 
    cidr_blocks = ["0.0.0.0/0"] 
  }
  tags = {
    Name        = "${var.env_name}-bastion-sg"
    Environment = var.env_name
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.env_name}-rds-sg"
  description = "Allow Postgres only from bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from bastion only"
    from_port       = 5432  
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env_name}-rds-sg"
    Environment = var.env_name
  }
}
