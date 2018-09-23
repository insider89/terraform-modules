resource "aws_launch_configuration" "ograb-lc" {
  name_prefix                 = "ograb-lc-${var.environment}-"
  image_id                    = "${var.image_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${aws_security_group.ograb-sg.id}"]
  enable_monitoring           = "${var.enable_monitoring}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "ograb-lb" {
  name               = "ograb-lb-${var.environment}"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${var.public_subnets}"]
}

resource "aws_autoscaling_group" "ograb-ag" {
  name                      = "ograb-ag-${var.environment}"
  launch_configuration      = "${aws_launch_configuration.ograb-lc.name}"
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  availability_zones        = ["${var.availability_zones}"]
  vpc_zone_identifier       = ["${var.private_subnets}"]
  health_check_grace_period = 60
  default_cooldown          = 300

  tags = [
    {
      key                 = "name"
      value               = "ograb"
      propagate_at_launch = true
    },
    {
      key                 = "environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ograb-sg" {
  vpc_id = "${var.vpc_id}"
  name   = "ograb-sg-${var.environment}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ograb-sg-rule1" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.ograb-sg.id}"
}

resource "aws_autoscaling_policy" "ograb-ag-pol-rm" {
  name                   = "ograb-ag-pol-rm"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.ograb-ag.name}"
}

resource "aws_autoscaling_policy" "ograb-ag-pol-add" {
  name                   = "ograb-ag-pol-add"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.ograb-ag.name}"
}

resource "aws_cloudwatch_metric_alarm" "ograb-cwa-scaledown" {
  alarm_name          = "ograb-cwa-${var.environment}-scaledown"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "${var.scaledown_threshold["eval_periods"]}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ApplicationELB"
  period              = "${var.scaledown_threshold["period"]}"
  statistic           = "Sum"
  threshold           = "${var.scaledown_threshold["threshold"]}"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ograb-ag.name}"
  }

  alarm_description = "This metric monitors CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.ograb-ag-pol-rm.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ograb-cwa-scaleup" {
  alarm_name          = "ograb-cwa-${var.environment}-scaleup"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "${var.scaleup_threshold["eval_periods"]}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ApplicationELB"
  period              = "${var.scaleup_threshold["period"]}"
  statistic           = "Sum"
  threshold           = "${var.scaleup_threshold["threshold"]}"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ograb-ag.name}"
  }

  alarm_description = "This metric monitors CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.ograb-ag-pol-add.arn}"]
}
