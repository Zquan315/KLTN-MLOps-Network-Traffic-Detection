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

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
