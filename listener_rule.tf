# A listener rule is needed only if a load balancer is in use.

# FIXME: Clean this up once wwe figure out what we need to do for NLBs.

resource "aws_lb_listener_rule" "default" {
  # FIXME: For now, we assume a listener rule is made only for an ALB.
  for_each = local.uses_alb ? toset([local.lb_name]) : []

  listener_arn = data.aws_lb_listener.selected[0].arn
  priority     = local.priority > 0 ? local.priority : null

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default[0].arn
  }

  dynamic "condition" {
    for_each = ["host_header"]
    content {
      field  = "host-header"
      values = [local.host_header]
    }
  }

  dynamic "condition" {
    # The path_pattern only applies for ALBs.
    for_each = local.uses_alb ? ["path_pattern"] : []
    content {
      field  = "path-pattern"
      values = [local.path_pattern]
    }
  }
}
