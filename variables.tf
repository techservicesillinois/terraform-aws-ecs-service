##########################################################################
# ECS/Fargate service configuration
##########################################################################
# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateService.html

variable "alias" {
  description = "Route 53 alias block"
  type = object({
    domain   = optional(string)
    hostname = optional(string)
  })
  default = null
}

# Autoscaling configuration.

variable "autoscale" {
  description = "Autoscale configuration"
  type = object({
    max_capacity = number
    min_capacity = number
    metrics = map(
      object({
        actions_enabled         = optional(bool, true)
        adjustment_type         = string
        cooldown                = optional(number, null)
        datapoints_to_alarm     = optional(number, null)
        evaluation_periods      = number
        metric_aggregation_type = string
        period                  = number
        statistic               = string
        # TODO: Validate that either lower or upper bound are non-null.
        down = object({
          comparison_operator         = string
          metric_interval_lower_bound = optional(number, null)
          metric_interval_upper_bound = optional(number, null)
          scaling_adjustment          = number
          threshold                   = number
        })
        # TODO: Validate that either lower or upper bound are non-null.
        up = object({
          comparison_operator         = string
          metric_interval_lower_bound = optional(number, null)
          metric_interval_upper_bound = optional(number, null)
          scaling_adjustment          = number
          threshold                   = number
        })
      })
    )
  })
  default = null

  validation {
    condition     = var.autoscale == null || try(length(var.autoscale.metrics) > 0, true)
    error_message = "The 'autoscale' block must have one or more metrics"
  }
}

variable "cluster" {
  description = "ECS cluster name"
  default     = "default"
}

variable "deployment_maximum_percent" {
  description = "The upper limit, as a percentage of the service's desired_count, of the number of running tasks that can be running in a service during a deployment."
  default     = null
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit, as a percentage of the service's desired_count, of the number of running tasks that must remain running and healthy in a service during a deployment."
  default     = null
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running"
  default     = 1
}

variable "health_check" {
  description = "Health check block"
  type = object({
    enabled             = optional(bool)
    healthy_threshold   = optional(number)
    interval            = optional(number)
    matcher             = optional(string)
    path                = optional(string)
    port                = optional(number)
    protocol            = optional(string)
    timeout             = optional(number)
    unhealthy_threshold = optional(number)
  })
  default = null
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 1800. Only valid for services configured to use load balancers."
  default     = 0
}

variable "launch_type" {
  description = "Launch type for the service. Valid values are EC2 and FARGATE."
  default     = "FARGATE"

  validation {
    condition     = try(contains(["EC2", "FARGATE"], var.launch_type), true)
    error_message = "The 'launch_type' is not one of the valid values 'EC2' or 'FARGATE'."
  }
}

# FIXME: Valid values for priority are natural numbers between 1 and 50000
variable "load_balancer" {
  description = "Load balancer block"
  type = object({
    certificate_domain   = optional(string)
    container_name       = optional(string)
    container_port       = optional(number)
    deregistration_delay = optional(number)
    host_header          = optional(string)
    name                 = optional(string)
    path_pattern         = optional(string, "*")
    port                 = optional(number, 443)
    priority             = optional(number)
    security_group_id    = optional(string)
  })
  default = null

  # Validate that load balancer name is specified if load_balancer block is present.

  validation {
    condition     = try(var.load_balancer.name != null && var.load_balancer.name != "", true)
    error_message = "If load_balancer block is specified, a load balancer name must be specified."
  }

  # Validate that priority is in range if load_balancer block is present.

  validation {
    # condition     = var.load_balancer == null || try(var.load_balancer.priority > 0 && var.load_balancer.priority < 50000, true)
    condition     = try(var.load_balancer.priority > 0 && var.load_balancer.priority < 50000, true)
    error_message = "If specified, priority must be in range 1 to 50000."
  }
}

variable "name" {
  description = "ECS service name"
}

variable "network_configuration" {
  description = "Network configuration block"
  type = object({
    assign_public_ip     = optional(bool, false)
    ports                = optional(list(number), [])
    security_group_ids   = optional(list(string), [])
    security_group_names = optional(list(string), [])
    subnet_ids           = optional(list(string), [])
    subnet_type          = optional(string)
    vpc                  = optional(string)
  })
  default = null

  # Validate that either subnet_ids or both subnet_type and vpc are defined.

  validation {
    # TODO: This validation rule should be made more robust.
    condition     = var.network_configuration == null || can(length(var.network_configuration.subnet_ids) > 0 || (var.network_configuration.subnet_type != null && var.network_configuration.vpc != null))
    error_message = "The 'network_configuration' block must define both 'subnet_type' and 'vpc', or must define 'subnet_ids'."
  }

  # Validate subnet_type (if specified).

  validation {
    condition     = try(contains(["campus", "private", "public"], var.network_configuration.subnet_type), true)
    error_message = "The 'subnet_type' specified in the 'network_configuration' block is not one of the valid values 'campus', 'private', or 'public'."
  }
}

variable "ordered_placement_strategy" {
  description = "Strategy rules taken into consideration during task placement, in descending order of precedence. Not compatible with Fargate."
  type = list(object({
    type  = string
    field = optional(string)
  }))
  default = null
}

variable "placement_constraints" {
  description = "Rules taken into consideration during task placement. Not compatible with Fargate."
  type = list(object({
    type       = string
    expression = optional(string)
  }))
  default = null
}

variable "platform_version" {
  description = "Platform version (only applies to Fargate)."
  type        = string
  default     = null
}

variable "service_discovery" {
  description = "Service discovery block"
  type = object({
    health_check_config = optional(object({
      failure_threshold = optional(number)
      resource_path     = optional(string)
      type              = optional(string)
    }))
    health_check_custom_config = optional(object({
      failure_threshold = optional(number) # Forces new resource per Terraform docs.
    }))
    name           = optional(string)
    namespace_id   = string
    routing_policy = optional(string, "MULTIVALUE")
    ttl            = optional(number, 60)
    type           = optional(string, "A")
  })
  default = null
}

variable "tags" {
  description = "Tags to be applied to resources where supported"
  type        = map(string)
  default     = {}
}

variable "task_definition" {
  description = "Task definition block"
  type = object({
    container_definition_file = optional(string)
    cpu                       = optional(number)           # Required for Fargate.
    memory                    = optional(number)           # Required for Fargate.
    network_mode              = optional(string, "awsvpc") # Normal use case.
    task_role_arn             = optional(string)
    template_variables = optional(object({
      docker_tag  = string
      region      = string
      registry_id = number
    }))
  })
  default = null
}

variable "task_definition_arn" {
  description = " The family and revision (family:revision) or full ARN of the task definition for the ECS service"
  default     = null
}

# FIXME: See if below statement is still true, and convert to object.
# stickiness MUST have a default otherwise Terraform will fail when
# the map is not defined!
variable "stickiness" {
  description = "A stickiness block. Valid only with application load balancers"

  type = map(any)
  default = {
    type    = "lb_cookie"
    enabled = false
  }
}

variable "volume" {
  description = "A list of volume blocks that containers may use"
  type = list(object({
    name      = string
    host_path = string
    docker_volume_configuration = object({
      scope         = string
      autoprovision = bool
      driver        = string
      driver_opts   = map(string)
      labels        = map(string)
    })
    efs_volume_configuration = object({
      file_system_id = string
      root_directory = string
    })
  }))
  default = []
}

# Debugging.

variable "_debug" {
  description = "Produce debug output (boolean)"
  type        = bool
  default     = false
}
