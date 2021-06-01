# A listener rule is created only if a load balancer is in use

resource "aws_alb_listener_rule" "default" {
  count        = length(var.load_balancer) > 0 && local.priority == 0 ? 1 : 0
  listener_arn = data.aws_lb_listener.selected[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default[0].arn
  }

  condition {
    path_pattern {
      values = [local.path_pattern]
    }
  }

  condition {
    host_header {
      values = [local.host_header]
    }
  }
}

resource "aws_alb_listener_rule" "set_priority" {
  count        = length(var.load_balancer) > 0 && local.priority > 0 ? 1 : 0
  listener_arn = data.aws_lb_listener.selected[0].arn
  priority     = local.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default[0].arn
  }

  condition {
    path_pattern {
      values = [local.path_pattern]
    }
  }

  condition {
    host_header {
      values = [local.host_header]
    }
  }
}
