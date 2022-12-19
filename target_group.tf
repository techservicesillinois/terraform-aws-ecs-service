# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html

# TODO : It is possible to attach additional containers on different
# ports using aws_lb_target_group_attachment. See
# https://www.terraform.io/docs/providers/aws/r/lb_target_group_attachment.html
# Should we support this?

resource "aws_lb_target_group" "default" {
  count = var.load_balancer != null ? 1 : 0

  deregistration_delay = var.load_balancer.deregistration_delay
  name                 = var.name
  port                 = var.load_balancer.container_port
  protocol             = "HTTP" # The path between the LB and containers is trusted.
  target_type          = var.task_definition.network_mode == "awsvpc" ? "ip" : "instance"
  tags                 = merge({ Name = var.name }, var.tags)
  vpc_id               = one(data.aws_lb.selected.*.vpc_id)

  # TODO: It wouild be really nice if Terraform would "short-circuit" and
  # not evaluate variables that it doesn't actually need to iterate over.

  dynamic "health_check" {
    for_each = toset(var.health_check != null ? [var.health_check] : [])
    content {
      enabled             = try(health_check.value.enabled, null)
      healthy_threshold   = try(health_check.value.healthy_threshold, null)
      interval            = try(health_check.value.interval, null)
      matcher             = try(health_check.value.matcher, null)
      path                = try(health_check.value.path, null)
      port                = try(health_check.value.port, null)
      protocol            = try(health_check.value.protocol, null)
      timeout             = try(health_check.value.timeout, null)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, null)
    }
  }

  dynamic "stickiness" {
    for_each = [var.stickiness]
    content {
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      enabled         = lookup(stickiness.value, "enabled", null)
      type            = stickiness.value.type
    }
  }
}
