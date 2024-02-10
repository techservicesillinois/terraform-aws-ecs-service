# For local.manage_listener_certificate to be set to a non-null value,
# both of the following conditions must apply:
#
# (1) The var.load_balancer variable must be defined. An example of an
#     ECS task that doesn't use a load balancer would be a daemon
#     process that doesn't accept traffic from other ECS tasks.
#
# (2) The var.load_balancer.certificate_domain object must be non-null.
#     Tasks using a private load balancer don't need SSL certificates
#     because AWS traffic within a VPC is considered secure.
#
# Assuming both of the preceding conditions are satisfied, the
# var.load_balancer.manage_listener_certificate object determines the
# value of local.manage_listener_certificates.
#
# * If the var.load_balancer.manage_listener_certificate object is true
#   (which is the default), the listener certificate is managed with
#   exactly one ECS task, and will have the same lifecycle.
#
# * If the var.load_balancer.manage_listener_certificate object is
#   false, the module assumes that a listener certificate is managed
#   independently in a separate configuration directory using the
#   terraform-aws-lb-listener-certificate module.
#
#   In this case, the listener certificate will persist beyond the
#   lifetime of any of the individual ECS tasks. This is useful where
#   multiple tasks share a host_header, and use path_pattern and
#   priority values to distinguish the task to which traffic should
#   be routed.

locals {
  manage_listener_certificate = try(var.load_balancer != null && var.load_balancer.certificate_domain != null && var.load_balancer.manage_listener_certificate, null)
}

data "aws_acm_certificate" "default" {
  count    = try(local.manage_listener_certificate == true, false) ? 1 : 0
  domain   = var.load_balancer.certificate_domain
  statuses = ["ISSUED"]
}

resource "aws_lb_listener_certificate" "default" {
  count           = try(local.manage_listener_certificate == true, false) ? 1 : 0
  listener_arn    = data.aws_lb_listener.selected[0].arn
  certificate_arn = data.aws_acm_certificate.default[0].arn
}
