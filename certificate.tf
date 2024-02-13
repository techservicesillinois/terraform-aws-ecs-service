# The value of local.manage_listener_certificate is null if no
# load_balancer block is defined, or no load balancer certificate
# domain is defined. This covers daemon-like tasks that don't
# use a load balancer, as well as tasks that have listeners
# on private load balancers (which do not use certificates because
# intra-VPC traffic is deemed secure, and takes place over port 80).
#
# Otherwise, the local.manage_listener_certificate takes on the
# value of the manage_listener_certificate's load_balancer block.
# The default is true, meaning that a listener certificate is
# managed along with the ECS task and has the same lifecycle.
#
# Set manage_listener_certificate to false when more than one ECS
# task uses the same host_header (which implies that > 1 ECS tasks
# share the listener certificate). In this case, the listener
# certificate should *NOT* be applied and destroyed with any
# particular ECS task.
#
# Use the terraform-aws-lb-listener-certificate module in a separate
# configuration directory to allow the listener certificate to persist
# independently of the state of any individual ECS tasks sharing the
# listener certificate.

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
