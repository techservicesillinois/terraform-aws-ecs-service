#output "autoscaling_target" {
# value = local.autoscale != null ? { for k, v in aws_appautoscaling_target.default : k => v.id } : null
#}

# These local variables exist solely to make the output variables more readable.

locals {
  autoscaling_alarm  = merge({ "down" = aws_cloudwatch_metric_alarm.down }, { "up" = aws_cloudwatch_metric_alarm.up })
  autoscaling_policy = merge({ "down" = aws_appautoscaling_policy.down }, { "up" = aws_appautoscaling_policy.up })
}

output "autoscaling_alarm" {
  value = var.autoscale != null ? { for k, v in local.autoscaling_alarm : k => { for mk, mv in v : mk => mv.arn } } : null
}

output "autoscaling_policy" {
  value = var.autoscale != null ? { for k, v in local.autoscaling_policy : k => { for mk, mv in v : mk => mv.arn } } : null
}

output "fqdn" {
  value = var.alias != null ? aws_route53_record.default[0].fqdn : null
}

output "id" {
  value = aws_ecs_service.default.id
}

output "security_group_id" {
  value = one(aws_security_group.default.*.id)
}

output "service_discovery_registry_arn" {
  value = try(one(aws_service_discovery_service.default.*.arn), null)
}

output "subnet_ids" {
  value = local.all_subnets
}

output "target_group_arn" {
  value = var.load_balancer != null ? aws_lb_target_group.default[0].arn : null
}

output "task_definition_arn" {
  value = local.task_definition_arn
}

# Debug outputs.

output "_autoscale_metrics" {
  value = (var._debug) ? local.autoscale_metrics : null
}

output "_container_definition_file" {
  value = (var._debug) ? local.container_definition_file : null
}

output "_container_definitions" {
  value = (var._debug) ? local.container_definitions : null
}

output "_health_check" {
  value = (var._debug) ? var.health_check : null
}

output "_load_balancer" {
  value = (var._debug) ? var.load_balancer : null
}

output "_network_configuration" {
  value = (var._debug) ? var.network_configuration : null
}

output "_service_discovery" {
  value = (var._debug) ? var.service_discovery : null
}

output "_task_definition" {
  value = (var._debug) ? var.task_definition : null
}
