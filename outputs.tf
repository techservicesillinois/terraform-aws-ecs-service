output "id" {
  value = element(
    concat(
      aws_ecs_service.awsvpc_all.*.id,
      aws_ecs_service.awsvpc_lb.*.id,
      aws_ecs_service.awsvpc_sd.*.id,
      aws_ecs_service.awsvpc.*.id,
      aws_ecs_service.all.*.id,
      aws_ecs_service.lb.*.id,
      aws_ecs_service.sd.*.id,
      aws_ecs_service.default.*.id,
    ),
    0,
  )
}

output "fqdn" {
  value = element(concat(aws_route53_record.default.*.fqdn, [""]), 0)
}

output "target_group_arn" {
  value = element(concat(aws_lb_target_group.default.*.arn, [""]), 0)
}

output "task_definition_arn" {
  value = local.task_definition_arn
}

output "security_group_id" {
  value = element(concat(aws_security_group.default.*.id, [""]), 0)
}

output "subnet_ids" {
  value = local.all_subnets
}
