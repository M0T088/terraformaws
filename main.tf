provider "aws" {
  region = "us-east-2"
}

resource "aws_key_pair" "ubuntu" {
  key_name   = "ubuntu"
  public_key = file("key.pub")
}

resource "aws_security_group" "ubuntu" {
  name = "ubuntu-security-group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = var.server_port
    to_port   = var.server_port
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform"
  }
}

resource "aws_instance" "ubuntu" {
  key_name      = aws_key_pair.ubuntu.key_name
  ami           = "ami-0a91cd140a1fc148a"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ubuntu.id]

  user_data = <<-EOF
          #!/bin/bash
          sudo apt-get update && \
          sudo apt-get install \
              apt-transport-https \
              ca-certificates \
              curl \
              gnupg-agent \
              software-properties-common && \
          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
          sudo apt-key fingerprint 0EBFCD88 && \
          sudo add-apt-repository \
              "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) \
              stable" && \
          sudo apt-get update && \
          sudo apt-get install docker-ce docker-ce-cli containerd.io && \
          sudo chmod 777 /var/run/docker.sock &
          EOF

  tags = {
    Name = "ubuntu"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("key")
    host        = self.public_ip
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 30
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

output "public_ip" {
  value = aws_instance.ubuntu.public_ip
  description = "The public IP of the web server"
}


