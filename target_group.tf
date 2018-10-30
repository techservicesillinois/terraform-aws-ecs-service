# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html

# TODO : It is possible to attach additional containers on different
# ports using aws_lb_target_group_attachment
# https://www.terraform.io/docs/providers/aws/r/lb_target_group_attachment.html
# Should we support this?

resource "aws_lb_target_group" "default" {
  count = "${length(var.load_balancer) > 0 ? 1 : 0}"
  name  = "${var.name}"
  port  = "${local.container_port}"

  # Valid vales for protocol are HTTP/HTTPS. We only support HTTP
  # because we trust the path between the load balancer and the
  # containers. If not then do NOT use a load balancer.
  protocol = "HTTP"

  vpc_id = "${local.lb_vpc_id}"

  deregistration_delay = "${local.deregistration_delay}"

  stickiness   = ["${var.stickiness}"]
  health_check = ["${var.health_check}"]
  target_type  = "${local.network_mode == "awsvpc" ? "ip" : "instance"}"
  tags         = "${var.tags}"
}
