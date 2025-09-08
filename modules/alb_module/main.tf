# modules/load_balancer_module/main.tf
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = var.load_balancer_type
  security_groups    = var.alb_security_group_id
  subnets            = var.public_subnet_ids
  tags = {
    Name = "alb"
  }
}

locals {
  routes_map = { for r in var.routes : r.name => r }
}

resource "aws_lb_target_group" "tg" {
  for_each = local.routes_map

  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = each.value.health_path
    protocol            = "HTTP"
    matcher             = coalesce(try(each.value.matcher, null), "200")
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[var.default_route_name].arn
  }
}

# Tạo listener rules cho các route KHÁC default (default dùng action mặc định)
resource "aws_lb_listener_rule" "rule" {
  for_each    = { for k, v in local.routes_map : k => v if k != var.default_route_name }
  listener_arn = aws_lb_listener.http.arn
  priority     = 10 + index(keys(local.routes_map), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    path_pattern { values = each.value.path_patterns }
  }
}