provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "available" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "test_sg" {
  name_prefix = "test-sg-1"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags = {
    Name = "test-sg"
  }
  vpc_id = data.aws_vpc.default.id
}


resource "aws_instance" "example_instance" {
  ami = "ami-0fcf52bcf5db7b003"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name = "manoj"
  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.test_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "terraform-instance"
  }

provisioner "file" {
  source      = "/home/ubuntu/file.zip"
  destination = "/home/ubuntu/file.zip"
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/ubuntu/manoj.pem")
    host        = aws_instance.example_instance.public_ip
  }
}

user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y
            sudo apt install docker.io -y
            sudo apt install unzip
            unzip /home/ubuntu/file.zip
            docker build -t website file/            
            docker run -d -p 80:80 website
            docker pull jenkins/jenkins:lts
            docker run -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home --name jenkins -d jenkins/jenkins:lts
            EOF


}


output "public_ip" {
  value = aws_instance.example_instance.public_ip
}

output "public_dns" {
  value = aws_instance.example_instance.public_dns
}

output "jenkins_url" {
  value = "http://${aws_instance.example_instance.public_dns}:8080"
}
