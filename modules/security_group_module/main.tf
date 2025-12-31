resource "aws_security_group" "security_group_public" {
  vpc_id      = var.vpc_id
  tags = {
    Name = "security_group_public"
  }
  dynamic "ingress" {
    for_each = var.ingress_rules_public
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description != null ? ingress.value.description : ""
    }
  }

  egress {
    from_port   = var.from_port_e_public
    to_port     = var.to_port_e_public
    protocol    = var.protocol_e_public
    cidr_blocks = var.cidr_blocks_e_public
  }
}

resource "aws_security_group" "security_group_private" {
  vpc_id      = var.vpc_id
  tags = {
    Name = "security_group_private"
  }
  ingress {
      from_port       = var.from_port_in_private
      to_port         = var.to_port_in_private
      protocol        = var.protocol_in_private
      security_groups = [aws_security_group.security_group_public.id]

  }
  egress {
    from_port   = var.from_port_e_private
    to_port     = var.to_port_e_private
    protocol    = var.protocol_e_private
    cidr_blocks = var.cidr_blocks_e_private
  }
}

resource "aws_security_group" "sg_alb" {
  vpc_id = var.vpc_id
  name   = "sg_alb"
  tags = {
    Name = "security_group_alb"
  }

  ingress {
    description      = "HTTPS from IPv4"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS from IPv6"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "sg_efs" {
  vpc_id = var.vpc_id
  name   = "sg_efs"
  tags = {
    Name = "security_group_efs"
  }

  # Allow NFS traffic from public security group (for monitoring instances)
  ingress {
    description     = "NFS from monitoring instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_public.id]
  }

  # Allow NFS traffic from private security group (if needed in the future)
  ingress {
    description     = "NFS from private instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_private.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
