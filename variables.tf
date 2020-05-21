##########################################################################
# ECS/Fargate service configuration
##########################################################################
# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CreateService.html

#### Required

variable "name" {
  description = "The name of the ECS service"
}

#### Optional

variable "task_definition" {
  description = "Task definition block (map)"
  type        = map(any)
  default     = {}
}

variable "task_definition_arn" {
  description = " The family and revision (family:revision) or full ARN of the task definition to run in the ECS service."
  default     = ""
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running"
  default     = 1
}

variable "launch_type" {
  description = "The launch type on which to run the service. The valid values are EC2 and FARGATE."
  default     = "FARGATE"
}

variable "cluster" {
  description = "A name of an ECS cluster"
  default     = "default"
}

variable "deployment_maximum_percent" {
  description = "The upper limit, as a percentage of the service's desired_count, of the number of running tasks that can be running in a service during a deployment."
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit, as a percentage of the service's desired_count, of the number of running tasks that must remain running and healthy in a service during a deployment."
  default     = 50
}

variable "ordered_placement_strategy" {
  # This variable may not be used with Fargate!
  description = "Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence. The maximum number of ordered_placement_strategy blocks is 5."
  type        = list(string)
  default     = []
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 1800. Only valid for services configured to use load balancers."
  default     = 0
}

variable "load_balancer" {
  description = "A load balancer block"
  type        = map(string)
  default     = {}
}

variable "placement_constraints" {
  # This variables may not be used with Fargate!
  description = "Rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10."
  type        = list(string)
  default     = []
}

variable "network_configuration" {
  description = "A network configuration block"
  type        = map(string)
  default     = {}
}

variable "service_discovery" {
  description = "A service discovery block"
  type        = map(any)
  default     = {}
}

variable "service_discovery_health_check_config" {
  description = "A service discovery health check config block"
  type        = map(string)
  default     = {}
}

variable "service_discovery_health_check_custom_config" {
  description = "A service discovery health check custom config block"
  type        = map(string)
  default     = {}
}

##########################################################################
# additional load balancer configuration
##########################################################################

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

variable "health_check" {
  description = "A health check block."
  type        = map(string)
  default     = {}
}

##########################################################################
# additonal task default configuration
##########################################################################

variable "volume" {
  description = "A set of volume blocks that containers in your task may use."
  type        = list(map(string))
  default     = []
}

##########################################################################
# misc definition
##########################################################################

variable "tags" {
  description = "Tags to be applied to resources where supported"
  type        = map(string)
  default     = {}
}

##########################################################################
# Route 53 configuration
##########################################################################

variable "alias" {
  description = "Route 53 alias block"
  type        = map(string)
  default     = {}
}

##########################################################################
# AutoScaling Configuration
##########################################################################
variable "autoscale" {
  description = "An autoscale block"
  type        = map(string)
  default     = {}
}
