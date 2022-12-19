locals {
  autoscale_metrics = { for k in try(keys(var.autoscale.metrics), {}) : k => var.autoscale.metrics[k] }
}

# Autoscaling target.

# TODO: Study (and document) how min_capacity and max_capacity interact with scaleable_dimension.

resource "aws_appautoscaling_target" "default" {
  for_each = var.autoscale != null ? { autoscale = var.autoscale } : {}

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = format("service/%s/%s", var.cluster, var.name)
  role_arn           = format("arn:aws:iam::%s:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService", data.aws_caller_identity.current.account_id)
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale-down alarm for each metric.

resource "aws_cloudwatch_metric_alarm" "down" {
  for_each = local.autoscale_metrics

  actions_enabled     = each.value.actions_enabled
  alarm_actions       = [aws_appautoscaling_policy.down[each.key].arn]
  alarm_description   = format("scale-down alarm for %s on %s metric", var.name, each.key)
  alarm_name          = format("ecs-%s-%s-down", var.name, lower(each.key))
  comparison_operator = each.value.down.comparison_operator
  datapoints_to_alarm = each.value.datapoints_to_alarm
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.key
  namespace           = "AWS/ECS"
  period              = each.value.period
  statistic           = each.value.statistic
  tags                = merge({ Name = var.name }, var.tags)
  threshold           = each.value.down.threshold

  dimensions = {
    ClusterName = var.cluster
    ServiceName = var.name
  }
}

# Scale-up alarm for each metric.

resource "aws_cloudwatch_metric_alarm" "up" {
  for_each = local.autoscale_metrics

  actions_enabled     = each.value.actions_enabled
  alarm_actions       = [aws_appautoscaling_policy.up[each.key].arn]
  alarm_description   = format("scale-up alarm for %s on %s metric", var.name, each.key)
  alarm_name          = format("ecs-%s-%s-up", var.name, lower(each.key))
  comparison_operator = each.value.up.comparison_operator
  datapoints_to_alarm = each.value.datapoints_to_alarm
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.key
  namespace           = "AWS/ECS"
  period              = each.value.period
  statistic           = each.value.statistic
  tags                = merge({ Name = var.name }, var.tags)
  threshold           = each.value.up.threshold

  dimensions = {
    ClusterName = var.cluster
    ServiceName = var.name
  }
}

# Scale-down policy for each metric.

resource "aws_appautoscaling_policy" "down" {
  for_each = local.autoscale_metrics

  name               = format("ecs-%s-%s-down", var.name, lower(each.key))
  resource_id        = aws_appautoscaling_target.default["autoscale"].resource_id
  scalable_dimension = aws_appautoscaling_target.default["autoscale"].scalable_dimension
  service_namespace  = aws_appautoscaling_target.default["autoscale"].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = each.value.adjustment_type
    cooldown                = each.value.cooldown
    metric_aggregation_type = each.value.metric_aggregation_type

    step_adjustment {
      metric_interval_lower_bound = each.value.down.metric_interval_lower_bound
      metric_interval_upper_bound = each.value.down.metric_interval_upper_bound
      scaling_adjustment          = each.value.down.scaling_adjustment
    }
  }
}

# Scale-up policy for each metric.

resource "aws_appautoscaling_policy" "up" {
  for_each = local.autoscale_metrics

  name               = format("ecs-%s-%s-up", var.name, lower(each.key))
  resource_id        = aws_appautoscaling_target.default["autoscale"].resource_id
  scalable_dimension = aws_appautoscaling_target.default["autoscale"].scalable_dimension
  service_namespace  = aws_appautoscaling_target.default["autoscale"].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = each.value.adjustment_type
    cooldown                = each.value.cooldown
    metric_aggregation_type = each.value.metric_aggregation_type

    step_adjustment {
      metric_interval_lower_bound = each.value.up.metric_interval_lower_bound
      metric_interval_upper_bound = each.value.up.metric_interval_upper_bound
      scaling_adjustment          = each.value.up.scaling_adjustment
    }
  }
}
