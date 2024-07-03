# NOTA BENE: The eight aws_ecs_service resources below are mutually
# exclusive. One and only one will ever be built.
#
# This code was tested with Terraform v1.3.7.
#
# For more information about ECS, see
#
#   https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html

# The aws_ecs_service resource supports both EC2 and FARGATE launch
# types, with FARGATE being this module's default. In either case,
# you must have an ECS cluster. In the case of FARGATE, Amazon
# manages the cluster instances. For EC2 launch types, you manage
# the EC2 instances comprising the cluster yourself.
#
# Learn more about managing ECS clusters with Terraform at
#
#   https://github.com/techservicesillinois/terraform-aws-ecs-cluster
#
# The terraform-aws-ecs-service module manages exactly one
# aws_ecs_service resource that supports a variety of optional
# features using dynamic blocks. There are three input variables
# that affect dynamic block creation.
#
# * The presence of a "load_balancer" input variable results in
#   the creation of a "load balancer" dynamic block.
#
# * The presence of a "network_configuration" input variable
#   results in a "network_configuration" dynamic block, which
#   is required for "awsvpc" network mode. "FARGATE" is the
#   default launch type. Since FARGATE runs *only* in "awsvpc"
#   mode, that value is the default network mode.
#
# * The presence of a "service_discovery" input variable results
#   in a "service_registries" dynamic block.

# Local variable contains list of security groups from various sources.

locals {
  security_groups = distinct(
    concat(
      aws_security_group.default.*.id,
      data.aws_security_group.selected.*.id,
      try(var.network_configuration.security_group_ids, [])
    )
  )
}

# Smooth transition for infrastructure created by old module versions.

# NOTE: We can't do multiple moved blocks to a single resource, even
# though they are mutually-exclusive. However, enumerating all but the
# most common use case (commented out) serves as documentation.

#moved {
# from = aws_ecs_service.all[0]
# to   = aws_ecs_service.default
#}

#moved {
# from = aws_ecs_service.awsvpc[0]
# to   = aws_ecs_service.default
#}

#moved {
# from = aws_ecs_service.awsvpc_all[0]
# to   = aws_ecs_service.default
#}

moved {
  from = aws_ecs_service.awsvpc_lb[0]
  to   = aws_ecs_service.default
}

#moved {
# from = aws_ecs_service.awsvpc_sd[0]
# to   = aws_ecs_service.default
#}

#moved {
# from = aws_ecs_service.default[0]
# to   = aws_ecs_service.default
#}

#moved {
# from = aws_ecs_service.lb[0]
# to   = aws_ecs_service.default
#}

#moved {
# from = aws_ecs_service.sd[0]
# to   = aws_ecs_service.default
#}

locals {
  tags = merge({ Name = var.name }, var.tags)
}

resource "aws_ecs_service" "default" {
  name                               = var.name
  launch_type                        = var.launch_type
  cluster                            = data.aws_ecs_cluster.selected.id
  task_definition                    = local.task_definition_arn
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  # enable_ecs_managed_tags            = true
  force_new_deployment              = var.force_new_deployment
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  platform_version                  = var.platform_version
  propagate_tags                    = var.propagate_tags
  tags                              = local.tags

  dynamic "load_balancer" {
    for_each = toset(var.load_balancer != null ? [var.load_balancer] : [])

    content {
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
      target_group_arn = aws_lb_target_group.default[0].arn
    }
  }

  dynamic "network_configuration" {
    for_each = toset(var.network_configuration != null ? [var.network_configuration] : [])

    content {
      assign_public_ip = network_configuration.value.assign_public_ip
      security_groups  = local.security_groups
      subnets          = local.all_subnets
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = toset(var.ordered_placement_strategy != null ? var.ordered_placement_strategy : [])

    content {
      field = ordered_placement_strategy.value.field
      type  = ordered_placement_strategy.value.type
    }
  }

  dynamic "placement_constraints" {
    for_each = toset(var.placement_constraints != null ? var.placement_constraints : [])

    content {
      expression = placement_constraints.value.expression
      type       = placement_constraints.value.type
    }
  }

  dynamic "service_registries" {
    for_each = toset(var.service_discovery != null ? [var.service_discovery] : [])

    content {
      registry_arn = one(aws_service_discovery_service.default.*.arn)
    }
  }
}
