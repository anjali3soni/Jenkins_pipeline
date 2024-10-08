provider "aws" {
  region = "ap-south-1"
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "jenkins-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["ap-south-1a"]
  public_subnets  = ["10.0.101.0/24"]
  enable_vpn_gateway = true
  tags = {
    Terraform = "true"
  }
}

resource "aws_instance" "public_instance" {
  ami                       = "ami-0ad21ae1d0696ad58"
  instance_type             = "t2.micro"
  subnet_id                 = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  key_name                  = "terraform"
  vpc_security_group_ids    = [aws_security_group.public_sg.id]
  tags = {
    Name = "Public_Instance"
  }
}
resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "Allow inbound SSH and HTTP traffic"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  tags = {
    Name = "public_sg"
  }
}


resource "aws_s3_bucket" "website_bucket" {
  bucket = "jenkins34234-s3-bucket-for-index-html-testing-39312345"
}
resource "aws_s3_bucket_public_access_block" "publicallow" {
  bucket = aws_s3_bucket.website_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.publicallow]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      },
    ]
  })
}
resource "aws_s3_object" "index" {
  bucket        = aws_s3_bucket.website_bucket.bucket
  key           = "index.html"
  source        = "./index.html"
  content_type  = "text/html"
  etag          = "${md5(file("./index.html"))}"
}
resource "aws_s3_bucket_website_configuration" "web-host-config" {
  bucket = aws_s3_bucket.website_bucket.id
  index_document {
    suffix = "index.html"
  }
}
output "s3_url" {
  description = "s3 obj url"
  value       = aws_s3_bucket_website_configuration.web-host-config.website_endpoint
}