resource "aws_launch_template" "launch_template" {
  name_prefix   = "launch_template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = var.security_group_id_public
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.volume_size
      volume_type = var.volume_type
    }
  }

  user_data = base64encode(templatefile(var.user_data_path, var.user_data_template_vars))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.name_instance
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = var.asg_name
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "ASG_Name"
    value               = var.asg_name
    propagate_at_launch = true
  }

  health_check_type         = "ELB"
  health_check_grace_period = 1200 
  
  # Termination policies - ưu tiên giữ instances mới nhất
  termination_policies = ["NewestInstance", "Default"]
  
  # Wait for capacity timeout - chờ instances healthy
  wait_for_capacity_timeout = "15m"
  
  # Force delete - tránh stuck khi destroy
  force_delete = true
  
  depends_on = [var.target_group_arns ]
}




# test alarms for scaling policies
resource "aws_sns_topic" "cloudwatch_alarms_topic" {
  name = "cloudwatch_alarms_topic"
}
# Tạo Subscription cho email
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alarms_topic.arn
  protocol  = "email"
  endpoint  = "tocongquan315@gmail.com"
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale_out_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale_in_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.asg_name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale out when CPU >= 70%"
  alarm_actions       = [aws_autoscaling_policy.scale_out_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}


# ==========================================
# Memory-based Scaling Policies
# ==========================================
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.asg_name}-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Scale out when Memory usage >= 80%"
  alarm_actions       = [aws_autoscaling_policy.scale_out_policy.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "${var.asg_name}-memory-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 120
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Scale in when Memory usage <= 40%"
  alarm_actions       = [aws_autoscaling_policy.scale_in_policy.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# ==========================================
# Disk-based Scaling Policies
# ==========================================
resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${var.asg_name}-disk-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Scale out when Disk usage >= 80%"
  alarm_actions       = [aws_autoscaling_policy.scale_out_policy.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
    path                 = "/"
    fstype               = "ext4"
  }
}