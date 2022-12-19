locals {
  internal_lb = one(data.aws_lb.selected.*.internal)
}

data "aws_route53_zone" "selected" {
  count = var.alias != null && var.load_balancer != null ? 1 : 0

  name         = var.alias.domain
  vpc_id       = local.internal_lb ? one(data.aws_lb.selected.*.vpc_id) : null
  private_zone = local.internal_lb
}

resource "aws_route53_record" "default" {
  count = var.alias != null && var.load_balancer != null ? 1 : 0

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = var.alias.hostname
  type    = "A"

  alias {
    name                   = one(data.aws_lb.selected.*.dns_name)
    zone_id                = one(data.aws_lb.selected.*.zone_id)
    evaluate_target_health = true
  }
}
