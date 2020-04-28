provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "publicsecg" {
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


resource "aws_security_group" "privatesecg" {
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




resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public_Subnet"
  }
}



resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private_Subnet"
  }
}



resource "aws_instance" "private" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private.id
  key_name                    = "MyKeyPair"
  availability_zone           = "eu-west-2a"
  vpc_security_group_ids      = [aws_security_group.privatesecg.id]

  tags = { Name = "private-instance" }

}

resource "aws_eip" "elas_nat" {
  vpc = true
  associate_with_private_ip = "10.0.0.12"
  depends_on                = ["aws_internet_gateway.gw"]
}




resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.elas_nat.id
  subnet_id     = aws_subnet.public.id
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

resource "aws_route_table_association" "publicRT" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.main.id
}




resource "aws_route_table" "private" {
  vpc_id     = aws_vpc.example.id
  route{  
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.ngw.id
}
}

resource "aws_route_table_association" "privateRT" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}







resource "aws_instance" "public" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true  
  key_name                    = "MyKeyPair"
  vpc_security_group_ids      = [aws_security_group.publicsecg.id]
  availability_zone           = "eu-west-2a"

  tags = { Name = "public-instance" }

}




