# Only one of the following resources will be built at any given time.

# This resource is built only when we're using service discovery with
# NEITHER health_check_config nor health_check_custom_config.

resource "aws_service_discovery_service" "default" {
  count = "${length(var.service_discovery) > 0 && length(var.service_discovery_health_check_config) == 0 && length(var.service_discovery_health_check_custom_config) == 0 ? 1 : 0}"

  name = "${local.namespace_name}"

  dns_config {
    namespace_id = "${local.namespace_id}"

    dns_records {
      ttl  = "${local.dns_ttl}"
      type = "${local.dns_type}"
    }

    routing_policy = "${local.dns_routing_policy}"
  }
}

# This resource is built only when we're using service discovery with
# health_check_custom_config but NOT health_check_config.

resource "aws_service_discovery_service" "health_check_custom" {
  count = "${length(var.service_discovery) > 0 && length(var.service_discovery_health_check_config) == 0 && length(var.service_discovery_health_check_custom_config) > 0 ? 1 : 0}"

  name = "${local.namespace_name}"

  dns_config {
    namespace_id = "${local.namespace_id}"

    dns_records {
      ttl  = "${local.dns_ttl}"
      type = "${local.dns_type}"
    }

    routing_policy = "${local.dns_routing_policy}"
  }

  health_check_custom_config = ["${var.service_discovery_health_check_custom_config}"]
}

# This resource is built only when we're using service discovery with
# health_check_config but NOT health_check_custom_config.

resource "aws_service_discovery_service" "health_check" {
  count = "${length(var.service_discovery) > 0 && length(var.service_discovery_health_check_config) > 0 && length(var.service_discovery_health_check_custom_config) == 0 ? 1 : 0}"

  name = "${local.namespace_name}"

  dns_config {
    namespace_id = "${local.namespace_id}"

    dns_records {
      ttl  = "${local.dns_ttl}"
      type = "${local.dns_type}"
    }

    routing_policy = "${local.dns_routing_policy}"
  }

  health_check_config = ["${var.service_discovery_health_check_config}"]
}

# This resource is built only when we're using service discovery with
# BOTH health_check_config AND health_check_custom_config.
#
# NOTE: Amazon does not currently support this combination, and an
#       error message will result when this is attempted.

resource "aws_service_discovery_service" "health_check_and_health_check_custom" {
  count = "${length(var.service_discovery) > 0 && length(var.service_discovery_health_check_config) > 0 && length(var.service_discovery_health_check_custom_config) > 0 ? 1 : 0}"

  name = "${local.namespace_name}"

  dns_config {
    namespace_id = "${local.namespace_id}"

    dns_records {
      ttl  = "${local.dns_ttl}"
      type = "${local.dns_type}"
    }

    routing_policy = "${local.dns_routing_policy}"
  }

  health_check_config        = ["${var.service_discovery_health_check_config}"]
  health_check_custom_config = ["${var.service_discovery_health_check_custom_config}"]
}
