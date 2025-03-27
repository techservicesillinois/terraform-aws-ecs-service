locals {
  all_subnets = distinct(concat(local.module_subnet_ids, try(var.network_configuration.subnet_ids, [])))
}

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "selected" {
  cluster_name = var.cluster
}

# Set boolean specifying whether to invoke get-subnets module to look up subnets.

locals {
  do_subnet_lookup = try(var.network_configuration.subnet_type != null && var.network_configuration.vpc != null, false)
}

# Look up matching subnets.

module "get-subnets" {
  source = "github.com/techservicesillinois/terraform-aws-util//modules/get-subnets?ref=v3.0.5"

  count       = local.do_subnet_lookup ? 1 : 0
  subnet_type = var.network_configuration.subnet_type
  vpc         = var.network_configuration.vpc
}

locals {
  module_subnet_ids = local.do_subnet_lookup ? try(module.get-subnets[0].subnets.ids, []) : []
}

## LB data sources

data "aws_lb" "selected" {
  count = var.load_balancer != null ? 1 : 0
  name  = var.load_balancer.name
}

data "aws_lb_listener" "selected" {
  count             = var.load_balancer != null ? 1 : 0
  load_balancer_arn = data.aws_lb.selected[0].arn
  port              = var.load_balancer.port
}

data "aws_security_group" "lb" {
  count = var.load_balancer != null ? 1 : 0
  name  = data.aws_lb.selected[0].name
}

data "aws_security_group" "selected" {
  count = try(length(var.network_configuration.security_group_names), 0)
  name  = var.network_configuration.security_group_names[count.index]
}

## Network data sources

data "aws_subnet" "selected" {
  count = try(length(var.network_configuration) > 0, false) ? 1 : 0
  id    = local.all_subnets[0]
}
