# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html

# TODO : It is possible to attach additional containers on different
# ports using aws_lb_target_group_attachment
# https://www.terraform.io/docs/providers/aws/r/lb_target_group_attachment.html
# Should we support this?

resource "aws_lb_target_group" "default" {
  count = length(var.load_balancer) > 0 ? 1 : 0
  name  = var.name
  port  = local.container_port

  # Valid vales for protocol are HTTP/HTTPS. We only support HTTP
  # because we trust the path between the load balancer and the
  # containers. If not then do NOT use a load balancer.
  protocol = "HTTP"

  vpc_id = local.lb_vpc_id

  deregistration_delay = local.deregistration_delay

  dynamic "stickiness" {
    for_each = [var.stickiness]
    content {
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      enabled         = lookup(stickiness.value, "enabled", null)
      type            = stickiness.value.type
    }
  }
  dynamic "health_check" {
    for_each = [var.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      interval            = lookup(health_check.value, "interval", null)
      matcher             = lookup(health_check.value, "matcher", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
    }
  }
  target_type = local.network_mode == "awsvpc" ? "ip" : "instance"
  tags        = var.tags
}
