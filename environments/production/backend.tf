terraform {
  backend "s3" {
    bucket         = "terraform-state-darpan-2026"
    key            = "production/terraform.tfstate"    
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
