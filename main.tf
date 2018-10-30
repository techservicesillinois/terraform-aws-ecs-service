# NOTA BENE: The eight aws_ecs_service resources below are mutually
# exclusive. One and only one will ever be built.
#
# This code was tested with Terraform v0.11.3
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html

# This resource is conditionally built when using awsvpc network
# mode with a load balancer and service discovery (e.g., works with
# FARGATE and EC2 launch_type). This is primarily useful for testing.

resource "aws_ecs_service" "awsvpc_all" {
  count = "${local.network_mode == "awsvpc" && length(var.load_balancer) > 0 && length(var.service_discovery) > 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  load_balancer {
    container_name   = "${local.container_name}"
    container_port   = "${local.container_port}"
    target_group_arn = "${aws_lb_target_group.default.arn}"
  }

  network_configuration {
    assign_public_ip = "${local.assign_public_ip}"
    security_groups  = ["${local.security_groups}"]
    subnets          = ["${local.all_subnets}"]
  }

  service_registries {
    registry_arn = "${element(concat(aws_service_discovery_service.default.*.arn, aws_service_discovery_service.health_check.*.arn, aws_service_discovery_service.health_check_custom.*.arn, aws_service_discovery_service.health_check_and_health_check_custom.*.arn), 0)}"
  }
}

# This resource is conditionally built when using awsvpc network mode
# with a load balancer (e.g., works with FARGATE and EC2 launch_type).

resource "aws_ecs_service" "awsvpc_lb" {
  count = "${local.network_mode == "awsvpc" && length(var.load_balancer) > 0 && length(var.service_discovery) == 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  load_balancer {
    container_name   = "${local.container_name}"
    container_port   = "${local.container_port}"
    target_group_arn = "${aws_lb_target_group.default.arn}"
  }

  network_configuration {
    assign_public_ip = "${local.assign_public_ip}"
    security_groups  = ["${local.security_groups}"]
    subnets          = ["${local.all_subnets}"]
  }
}

# This resource is conditionally built when using awsvpc network mode
# with service discovery (which implies no load balancer).

resource "aws_ecs_service" "awsvpc_sd" {
  count = "${local.network_mode == "awsvpc" && length(var.load_balancer) == 0 && length(var.service_discovery) > 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  network_configuration {
    assign_public_ip = "${local.assign_public_ip}"
    security_groups  = ["${local.security_groups}"]
    subnets          = ["${local.all_subnets}"]
  }

  service_registries {
    registry_arn = "${element(concat(aws_service_discovery_service.default.*.arn, aws_service_discovery_service.health_check.*.arn, aws_service_discovery_service.health_check_custom.*.arn, aws_service_discovery_service.health_check_and_health_check_custom.*.arn), 0)}"
  }
}

# This resource is conditionally built when using awsvpc network
# mode without a load balancer or service discovery.

resource "aws_ecs_service" "awsvpc" {
  count = "${local.network_mode == "awsvpc" && length(var.load_balancer) == 0 && length(var.service_discovery) == 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  network_configuration {
    assign_public_ip = "${local.assign_public_ip}"
    security_groups  = ["${local.security_groups}"]
    subnets          = ["${local.all_subnets}"]
  }
}

# This resource is conditionally built when not using awsvpc network
# mode, with a load balancer and service discovery (e.g., bridge
# or host mode: only works with launch_type EC2).

resource "aws_ecs_service" "all" {
  count = "${local.network_mode != "awsvpc" && length(var.load_balancer) > 0 && length(var.service_discovery) > 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  load_balancer {
    container_name   = "${local.container_name}"
    container_port   = "${local.container_port}"
    target_group_arn = "${aws_lb_target_group.default.arn}"
  }

  service_registries {
    registry_arn = "${element(concat(aws_service_discovery_service.default.*.arn, aws_service_discovery_service.health_check.*.arn, aws_service_discovery_service.health_check_custom.*.arn, aws_service_discovery_service.health_check_and_health_check_custom.*.arn), 0)}"
  }
}

# This resource is conditionally built when not using awsvpc network
# mode, with a load balancer (e.g., bridge or host mode: only works
# with launch_type EC2).

resource "aws_ecs_service" "lb" {
  count = "${local.network_mode != "awsvpc" && length(var.load_balancer) > 0 && length(var.service_discovery) == 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  load_balancer {
    container_name   = "${local.container_name}"
    container_port   = "${local.container_port}"
    target_group_arn = "${aws_lb_target_group.default.arn}"
  }
}

# This resource is conditionally built when not using awsvpc network mode
# with service discovery (which implies no load balancer). This applies to
# bridge, host, and none modes, and only works with launch_type EC2.

resource "aws_ecs_service" "sd" {
  count = "${local.network_mode != "awsvpc" && length(var.load_balancer) == 0 && length(var.service_discovery) > 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  service_registries {
    registry_arn = "${element(concat(aws_service_discovery_service.default.*.arn, aws_service_discovery_service.health_check.*.arn, aws_service_discovery_service.health_check_custom.*.arn, aws_service_discovery_service.health_check_and_health_check_custom.*.arn), 0)}"
  }
}

# This resource is conditionally built when not using awsvpc network
# mode without a load balancer or service discovery. This applies
# to bridge, host, and none modes, and only works with launch_type
# EC2. This is useful when running backend services that do not
# require inbound traffic.

resource "aws_ecs_service" "default" {
  count = "${local.network_mode != "awsvpc" && length(var.load_balancer) == 0 && length(var.service_discovery) == 0 ? 1 : 0}"

  name            = "${var.name}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.selected.id}"
  task_definition = "${var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn}"
  desired_count   = "${var.desired_count}"

  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"

  placement_constraints      = "${var.placement_constraints}"
  ordered_placement_strategy = "${var.ordered_placement_strategy}"
}
