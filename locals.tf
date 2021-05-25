# alias map
locals {
  alias_domain   = lookup(var.alias, "domain", "")
  alias_hostname = lookup(var.alias, "hostname", var.name)
}

# load_balancer map
locals {
  lb_name = lookup(var.load_balancer, "name", "")
  lb_port = tonumber(lookup(var.load_balancer, "port", 443))

  certificate_domain = lookup(var.load_balancer, "certificate_domain", "")

  container_name = lookup(var.load_balancer, "container_name", "")
  container_port = tonumber(lookup(var.load_balancer, "container_port", 0))

  host_header  = lookup(var.load_balancer, "host_header", "")
  path_pattern = lookup(var.load_balancer, "path_pattern", "*")

  # Valid values for priority are natural numbers between 1 and 50000
  deregistration_delay = tonumber(lookup(var.load_balancer, "deregistration_delay", 300))
  lb_security_group_id = lookup(var.load_balancer, "security_group_id", "")
  priority             = tonumber(lookup(var.load_balancer, "priority", 0))
}

# task_definition map
locals {
  container_definition_file = lookup(
    var.task_definition,
    "container_definition_file",
    "containers.json",
  )
  cpu           = lookup(var.task_definition, "cpu", 256)
  memory        = lookup(var.task_definition, "memory", 512)
  network_mode  = lookup(var.task_definition, "network_mode", "awsvpc")
  task_role_arn = lookup(var.task_definition, "task_role_arn", "")
}

# service_discovery map
locals {
  dns_routing_policy = lookup(var.service_discovery, "routing_policy", "MULTIVALUE")
  dns_ttl            = lookup(var.service_discovery, "ttl", 60)
  dns_type           = lookup(var.service_discovery, "type", "A")
  namespace_name     = lookup(var.service_discovery, "name", var.name)
  namespace_id       = lookup(var.service_discovery, "namespace_id", "")
}

# network_configuration map
locals {
  assign_public_ip = lookup(var.network_configuration, "assign_public_ip", false)
  ports            = compact(split(" ", lookup(var.network_configuration, "ports", "")))

  nc_security_groups = compact(
    split(
      " ",
      lookup(var.network_configuration, "security_groups", ""),
    ),
  )
  nc_security_group_names = compact(
    split(
      " ",
      lookup(var.network_configuration, "security_group_names", ""),
    ),
  )
  subnets = compact(split(" ", lookup(var.network_configuration, "subnets", "")))
  tier    = lookup(var.network_configuration, "tier", "")
  vpc     = lookup(var.network_configuration, "vpc", "")
}

# FIXME: This might break with NLBs.

locals {
  security_groups = distinct(
    concat(
      aws_security_group.default.*.id,
      data.aws_security_group.selected.*.id,
      local.nc_security_groups,
    ),
  )
}

output "zzz_sg" {
  value = local.security_groups
}

# autoscaling
locals {
  scale_down_name = lookup(var.autoscale, "autoscale_scale_down", "${var.name}-down")
  scale_up_name   = lookup(var.autoscale, "autoscale_scale_up", "${var.name}-up")
}
