resource "aws_instance" "bastion" {
  ami           = var.ami_id        
  instance_type = "t2.micro"        
  subnet_id     = var.public_subnet_id 
  key_name = var.key_name
  vpc_security_group_ids = [var.bastion_sg_id]
  tags = {
    Name        = "${var.env_name}-bastion"
    Environment = var.env_name
    Role        = "bastion"
  }
}
