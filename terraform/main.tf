# 1. Generate SSH Key (Matches your providers.tf)
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = var.private_key_path
  file_permission = "0600"
}

# 2. Security Group (Matches your requirements for port 22 and 5001)
resource "aws_security_group" "builder_sg" {
  name        = "jenkins-project-sg"
  description = "Allow SSH and Flask App"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Senior Tip: In prod, use your specific IP
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Vital for pulling Docker images!
  }
}

# 3. EC2 Instance (Named 'builder_instance' to fit your outputs.tf)
resource "aws_instance" "builder_instance" {
  ami           = var.ami_id != "" ? var.ami_id : "ami-09040d770ff222417" # Ubuntu 22.04 default
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.builder_sg.id]

  # Enables IMDSv2 for your app.py to get the IP safely
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" 
  }

  user_data = file("user_data.sh")

  tags = {
    Name = "JBP-Builder-Instance"
  }
}