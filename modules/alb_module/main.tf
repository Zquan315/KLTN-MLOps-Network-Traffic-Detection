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

resource "aws_lb_target_group" "tg_frontend" {
  name     = "tg-frontend"
  port     = var.frontend_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 4
    unhealthy_threshold = 2
  }
}

# resource "aws_lb_target_group" "tg_backend" {
#   name     = "tg-backend"
#   port     = var.backend_port
#   protocol = "HTTP"
#   vpc_id   = var.vpc_id

#   health_check {
#     path                = "/students"
#     protocol            = "HTTP"
#     matcher             = "200"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 4
#     unhealthy_threshold = 2
#   }
# }

resource "aws_lb_listener" "listener_frontend" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_frontend.arn
  }
}

# resource "aws_lb_listener_rule" "backend_rule" {
#   listener_arn = aws_lb_listener.listener_frontend.arn
#   priority     = 100
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tg_backend.arn
#   }
#   condition {
#     path_pattern {
#       values = ["/students", "/students/*"]
#     }
#   }
# }