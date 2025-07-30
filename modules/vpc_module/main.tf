resource "aws_vpc" "vpc" {

    cidr_block = var.cidr_block_value
    enable_dns_hostnames = var.dns_hostnames_value
    enable_dns_support = var.dns_support_value
    tags = {
        Name = "vpc"
    }
}

resource "aws_subnet" "subnet_private" {
    count = var.subnet_count_value
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_block_private_value[count.index]
    availability_zone = var.availability_zone_private_value[count.index]
    map_public_ip_on_launch = var.map_public_ip_on_launch_private_value
    tags = {
        Name = "subnet-private-${count.index}"
    }
}

resource "aws_subnet" "subnet_public" {
    count = var.subnet_count_value
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_block_public_value[count.index]
    availability_zone = var.availability_zone_public_value[count.index] 
    map_public_ip_on_launch = var.map_public_ip_on_launch_public_value
    tags = {
        Name = "subnet-public-${count.index}"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "igw"
    }
}

resource "aws_security_group" "security_group_default" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "security-group-default"
    }
  
}