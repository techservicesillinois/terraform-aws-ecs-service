locals {
  sd_name = try(var.service_discovery.name, var.name)
}

resource "aws_service_discovery_service" "default" {
  count = try(var.service_discovery != null, false) ? 1 : 0

  name = local.sd_name

  dns_config {
    namespace_id = var.service_discovery.namespace_id

    dns_records {
      ttl  = var.service_discovery.ttl
      type = var.service_discovery.type
    }

    routing_policy = var.service_discovery.routing_policy
  }

  # TODO: It wouild be really nice if Terraform would "short-circuit" and not evaluate
  # variables that it doesn't actually need to iterate over.

  dynamic "health_check_config" {
    for_each = try([var.service_discovery.health_check_config], [])
    content {
      failure_threshold = try(health_check_config.value.failure_threshold, null)
      resource_path     = try(health_check_config.value.resource_path, null)
      type              = try(health_check_config.value.type, null)
    }
  }

  # TODO: It wouild be really nice if Terraform would "short-circuit" and not evaluate
  # variables that it doesn't actually need to iterate over.

  # NOTE: The health_check_custom_config attribute *always* forces replacement. See
  #
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service#health_check_custom_config

  dynamic "health_check_custom_config" {
    for_each = try([var.service_discovery.health_check_custom_config], [])
    content {
      failure_threshold = try(health_check_custom_config.value.failure_threshold, null)
    }
  }
}
