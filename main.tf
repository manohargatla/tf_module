## creating vpc
resource "aws_vpc" "lb_vpc" {
  cidr_block = var.lb_vpc_info.lb_vpc_cidr
  tags = {
    Name = "lb_vpc"
  }
}
## creating subnet
resource "aws_subnet" "lb_subnet" {
  count             = length(var.lb_vpc_info.lb_subnet_names)
  vpc_id            = aws_vpc.lb_vpc.id
  cidr_block        = cidrsubnet(var.lb_vpc_info.lb_vpc_cidr, 8, count.index)
  availability_zone = "${var.region}${var.lb_vpc_info.lb_subnets_names_azs[count.index]}"
  tags = {
    Name = var.lb_vpc_info.lb_subnet_names[count.index]
  }
  depends_on = [
    aws_vpc.lb_vpc
  ]

}
## creating internetgate_way
resource "aws_internet_gateway" "igw_lb" {
  vpc_id = aws_vpc.lb_vpc.id
  tags = {
    Name = "igw_lb"
  }
  depends_on = [
    aws_vpc.lb_vpc
  ]
}
## creating route_table
resource "aws_route_table" "route_table_lb" {
  vpc_id = aws_vpc.lb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_lb.id
  }
  tags = {
    Name = "igw_lb"
  }
  depends_on = [
    aws_internet_gateway.igw_lb
  ]
}
## creating route_table association
resource "aws_route_table_association" "lb_main_rt_association" {
  subnet_id      = aws_subnet.lb_subnet[0].id
  route_table_id = aws_route_table.route_table_lb.id
  depends_on = [
    aws_route_table.route_table_lb
  ]

}
resource "aws_route_table_association" "lb_main_rt_association1" {
  subnet_id      = aws_subnet.lb_subnet[1].id
  route_table_id = aws_route_table.route_table_lb.id
  depends_on = [
    aws_route_table.route_table_lb
  ]

}
## create security group
resource "aws_security_group" "terraformlb" {
  name        = "terraformlb"
  vpc_id      = aws_vpc.lb_vpc.id
  description = "allow all ports"
  ingress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }

  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }

  depends_on = [
    aws_subnet.lb_subnet
  ]
}
## create keypair
resource "aws_key_pair" "deployer" {
  key_name   = "terraform3"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyNRL9nyxUnjeqSr92yVqV4ImkfwR6qYQrBBR5+eaxrCDQhIoHUtgiG0YXjrhXl6E6ErKiZBgwGjjFsMqjdzsfS9kHiawTMxTr4ilwCfOChgDfR5t5e3L/X4F/ZjCZiK1qNha+/DC5r/dGwhB579yxXSUxVWfGOP4buGWkWBWpmrN94EMmtFdyBSjnjMardSV2mXXPjPDNDudDUMEsQr4P8aAbiOj9VCf2tpQswElkjA4IZ8DfIfeIwKYsR11uDAqZrSf96TxFXN6OCKOnqu4DSWxFbKywffS5XG+nTC1+oee/ftdL6rlJpg/VaTN4Bqfsk9px/redvXlNFUsaZqrm5UiLCS7QGO/HfPa57JQBsS+jv2fURQfYMg35otxtbE3+IIHLzmdNnQOVU/scTyuO73kHrU2w0zTqfbMbqm7CqpnBfrdyzI4+AnV/4HtYojxGTZR6S3oV0azc7eKAGyeUjMttTuVbDYlQInkvZvS4SrFSfRTk+v1CFX0IJvSlVFE= dell@DESKTOP-G8OJBDS"
}

## create EC2 instance
resource "aws_instance" "red" {
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  ami                         = "ami-007855ac798b5175e"
  subnet_id                   = aws_subnet.lb_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.terraformlb.id]
  key_name                    = "terraform3"
  user_data                   = file("./day10/tf_modules/spc.sh")
  tags = {
    Name = "red"
  }
  depends_on = [
    aws_security_group.terraformlb
  ]
}

## create null resoure
  resource "null_resource" "spc" {
  triggers = {
    rollout_versions = var.lb_vpc_info.rollout_versions
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host = aws_instance.red.public_ip
  }
  provisioner "remote-exec" {
  inline = [
    "sudo apt update",
    "sudo apt install openjdk-17-jdk maven -y",
    "git clone https://github.com/spring-projects/spring-petclinic.git",
    "cd spring-petclinic",
    "./mvn package",
  ]
}
}
resource "aws_instance" "green" {
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  ami                         = "ami-007855ac798b5175e"
  subnet_id                   = aws_subnet.lb_subnet[1].id
  vpc_security_group_ids      = [aws_security_group.terraformlb.id]
  key_name                    = "terraform3"
  user_data                   = file("./day10/tf_modules/spc1.sh")
  tags = {
    Name = "green"
  }
  depends_on = [
    aws_security_group.terraformlb
  ]
}
## create null resoure
resource "null_resource" "spc1" {
  triggers = {
    rollout_versions = var.lb_vpc_info.rollout_versions
  }
}
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host = aws_instance.green.public_ip
  }
  provisioner "remote-exec" {
  inline = [
    "sudo apt update",
    "sudo apt install openjdk-17-jdk maven -y",
    "git clone https://github.com/spring-projects/spring-petclinic.git",
    "cd spring-petclinic",
    "./mvn package",
  ]
}
