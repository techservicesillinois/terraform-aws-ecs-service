data "aws_acm_certificate" "default" {
  count    = "${local.certificate_domain != "" ? 1 : 0}"
  domain   = "${local.certificate_domain}"
  statuses = ["ISSUED"]
}

resource "aws_lb_listener_certificate" "default" {
  count           = "${local.certificate_domain != "" ? 1 : 0}"
  listener_arn    = "${data.aws_lb_listener.selected.0.arn}"
  certificate_arn = "${data.aws_acm_certificate.default.0.arn}"
}
