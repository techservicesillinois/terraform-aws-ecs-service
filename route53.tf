data "aws_route53_zone" "selected" {
  count = length(var.alias) > 0 && length(var.load_balancer) > 0 ? 1 : 0

  name         = local.alias_domain
  vpc_id       = local.internal_lb == true ? local.lb_vpc_id : ""
  private_zone = local.internal_lb
}

locals {
  internal_lb = element(concat(data.aws_lb.selected.*.internal, [""]), 0)
}

resource "aws_route53_record" "default" {
  count = length(var.alias) > 0 && length(var.load_balancer) > 0 ? 1 : 0

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = local.alias_hostname
  type    = "A"

  alias {
    name                   = element(concat(data.aws_lb.selected.*.dns_name, [""]), 0)
    zone_id                = element(concat(data.aws_lb.selected.*.zone_id, [""]), 0)
    evaluate_target_health = true
  }
}
