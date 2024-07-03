# Listener rule is created only if a load balancer is specified.

# NOTE: These mutually-exclusive resources can't be combined because a
# null value is treated by Terraform differently than simply not
# specifying a priority.

resource "aws_alb_listener_rule" "default" {
  count = try(var.load_balancer.priority == null, false) ? 1 : 0

  listener_arn = data.aws_lb_listener.selected[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default[0].arn
  }

  condition {
    path_pattern {
      values = [var.load_balancer.path_pattern]
    }
  }

  condition {
    host_header {
      values = [var.load_balancer.host_header]
    }
  }

  tags = local.tags
}

resource "aws_alb_listener_rule" "set_priority" {
  count = try(var.load_balancer.priority != null, false) ? 1 : 0

  listener_arn = data.aws_lb_listener.selected[0].arn
  priority     = var.load_balancer.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default[0].arn
  }

  condition {
    path_pattern {
      values = [var.load_balancer.path_pattern]
    }
  }

  condition {
    host_header {
      values = [var.load_balancer.host_header]
    }
  }

  tags = local.tags
}
