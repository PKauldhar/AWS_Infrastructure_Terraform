provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.example.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port   = 22
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_subnet" "example_1" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "terraform"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "main" {
  vpc_id     = aws_vpc.example.id
  route{  
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.example_1.id
  route_table_id = aws_route_table.main.id
}



resource "aws_instance" "terraform" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.example_1.id
  associate_public_ip_address = true  
  key_name                    = "MyKeyPair"

  tags = { Name = "instanceinterra" }

}
