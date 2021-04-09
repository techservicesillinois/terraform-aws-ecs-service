locals {
  all_subnets = distinct(
    concat(flatten(data.aws_subnet_ids.selected.*.ids), local.subnets),
  )
  lb_vpc_id     = element(concat(data.aws_lb.selected.*.vpc_id, [""]), 0)
  subnet_vpc_id = element(concat(data.aws_subnet.selected.*.vpc_id, [""]), 0)
}

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "selected" {
  cluster_name = var.cluster
}

locals {
  # FIXME: This will break as written for non-load-balanced services.
  is_alb = (data.aws_lb.selected[0].load_balancer_type == "application") ? true : false
  is_nlb = (data.aws_lb.selected[0].load_balancer_type == "network") ? true : false
  # # TODO: Stolen from terraform-aws-lb; not yet used here.
  # needs_certificate = local.is_alb && ! var.internal
}

## LB data sources

data "aws_lb" "selected" {
  count = length(var.load_balancer) > 0 ? 1 : 0
  name  = local.lb_name
}

data "aws_lb_listener" "selected" {
  count             = local.is_alb && length(var.load_balancer) > 0 ? 1 : 0
  load_balancer_arn = data.aws_lb.selected[0].arn
  port              = local.lb_port
}

data "aws_security_group" "lb" {
  count = local.is_alb && length(var.load_balancer) > 0 ? 1 : 0
  name  = data.aws_lb.selected[0].name
}

data "aws_security_group" "selected" {
  count = length(local.nc_security_group_names)
  name  = local.nc_security_group_names[count.index]
}

## Network data sources

data "aws_subnet" "selected" {
  count = length(var.network_configuration) > 0 ? 1 : 0
  id    = local.all_subnets[0]
}

data "aws_vpc" "selected" {
  count = local.tier != "" ? 1 : 0

  tags = {
    Name = local.vpc
  }
}

data "aws_subnet_ids" "selected" {
  count  = local.tier != "" ? 1 : 0
  vpc_id = data.aws_vpc.selected[0].id

  tags = {
    Tier = local.tier
  }
}
