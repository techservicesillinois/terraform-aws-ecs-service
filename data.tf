locals {
  all_subnets = distinct(
    concat(flatten(module.get-subnets.subnets.ids), local.subnets),
  )
  lb_vpc_id     = element(concat(data.aws_lb.selected.*.vpc_id, [""]), 0)
  subnet_vpc_id = element(concat(data.aws_subnet.selected.*.vpc_id, [""]), 0)
}

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "selected" {
  cluster_name = var.cluster
}


module "get-subnets" {
  source = "github.com/techservicesillinois/terraform-aws-util//modules/get-subnets?ref=v3.0.4"

  subnet_type = local.subnet_type
  vpc         = local.vpc
}
## LB data sources

data "aws_lb" "selected" {
  count = length(var.load_balancer) > 0 ? 1 : 0
  name  = local.lb_name
}

data "aws_lb_listener" "selected" {
  count             = length(var.load_balancer) > 0 ? 1 : 0
  load_balancer_arn = data.aws_lb.selected[0].arn
  port              = local.lb_port
}

data "aws_security_group" "lb" {
  count = length(var.load_balancer) > 0 ? 1 : 0
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
