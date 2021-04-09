# Local variables for convenience due to frequent use in tests (e.g., in "for_each").

locals {
  # Do we use a load balancer (any type)?
  uses_lb = length(var.load_balancer) > 0

  # Do we use an application load balancer (ALB)?
  uses_alb = local.uses_lb && (data.aws_lb.selected[0].load_balancer_type == "application")

  # Do we use a network load balancer (NLB)?
  uses_nlb = local.uses_lb && (data.aws_lb.selected[0].load_balancer_type == "network")

  # TODO: Stolen from terraform-aws-lb; not yet used here.
  # Do we use an ACM certificate? (See route53.tf for definition of local.internal_lb.)
  uses_certificate = local.uses_alb && ! local.internal_lb
}

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

## LB data sources

data "aws_lb" "selected" {
  count = length(var.load_balancer) > 0 ? 1 : 0
  name  = local.lb_name
}

data "aws_lb_listener" "selected" {
  count             = local.uses_alb ? 1 : 0
  load_balancer_arn = data.aws_lb.selected[0].arn
  port              = local.lb_port
}

data "aws_security_group" "lb" {
  count = local.uses_alb ? 1 : 0
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
