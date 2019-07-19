######################################################################################
####################### AUTO SCALING & CLOUD WATCH ALARMS ############################
########## The autoscaling policies to scale the ecs service up and down. ############
######################################################################################

# CLOUDWATCH ALARM to monitor the memory utilization of a service
resource "aws_cloudwatch_metric_alarm" "alarm_scale_down" {
  count               = "${length(var.autoscale) > 0 ? 1 : 0}"
  alarm_description   = "Scale down alarm for ${var.name}"
  namespace           = "AWS/ECS"
  alarm_name          = "${local.scale_down_name}"
  alarm_actions       = ["${aws_appautoscaling_policy.policy_scale_down.arn}"]

  comparison_operator = "${lookup(var.autoscale, "scale_down_comparison_operator")}"
  threshold           = "${lookup(var.autoscale, "scale_down_threshold")}"  
  evaluation_periods  = "${lookup(var.autoscale, "evaluation_periods")}"
  metric_name         = "${lookup(var.autoscale, "metric_name")}"
  period              = "${lookup(var.autoscale, "period", "180")}"
  statistic           = "${lookup(var.autoscale, "statistic", "Average")}"
  datapoints_to_alarm = "${lookup(var.autoscale, "datapoints_to_alarm", "3")}"
  
  dimensions {
    ClusterName = "${var.cluster}"
    ServiceName = "${var.name}"
  }
}

# CLOUDWATCH ALARM  to monitor memory utilization of a service
resource "aws_cloudwatch_metric_alarm" "alarm_scale_up" {
  count             = "${length(var.autoscale) > 0 ? 1 : 0}"
  alarm_description = "Scale up alarm for ${var.name}"
  namespace         = "AWS/ECS"
  alarm_name        = "${local.scale_up_name}"
  alarm_actions     = ["${aws_appautoscaling_policy.policy_scale_up.arn}"]

  comparison_operator = "${lookup(var.autoscale, "scale_up_comparison_operator")}"
  threshold           = "${lookup(var.autoscale, "scale_up_threshold")}"
  evaluation_periods  = "${lookup(var.autoscale, "evaluation_periods")}"
  metric_name         = "${lookup(var.autoscale, "metric_name")}"
  period              = "${lookup(var.autoscale, "period", 180)}"
  statistic           = "${lookup(var.autoscale, "statistic", "Average")}"
  datapoints_to_alarm = "${lookup(var.autoscale, "datapoints_to_alarm", "3")}"

  dimensions {
    ClusterName = "${var.cluster}"
    ServiceName = "${var.name}"
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  count        = "${length(var.autoscale) > 0 ? 1 : 0}"
  max_capacity = "${lookup(var.autoscale, "autoscale_max_capacity", "5")}"
  min_capacity = "${lookup(var.autoscale, "service_desired_count", "1")}"
  resource_id  = "service/${var.cluster}/${var.name}"
  role_arn     = "${format("arn:aws:iam::%s:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService",
                                 data.aws_caller_identity.current.account_id)}"

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

#Set up the memory utilization policy for scale down when the cloudwatch alarm gets triggered.
resource "aws_appautoscaling_policy" "policy_scale_down" {
  count              = "${length(var.autoscale) > 0 ? 1 : 0}"
  name               = "${local.scale_down_name}"
  resource_id        = "${aws_appautoscaling_target.ecs_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "${lookup(var.autoscale, "adjustment_type")}"
    cooldown                = "${lookup(var.autoscale, "cooldown")}"
    metric_aggregation_type = "${lookup(var.autoscale, "aggregation_type", "Average")}"

    step_adjustment {
      metric_interval_upper_bound = "${lookup(var.autoscale, "scale_down_interval_lower_bound", "0")}"
      scaling_adjustment          = "${lookup(var.autoscale, "scale_down_adjustment")}"
    }
  }
}

#Set up the memory utilization policy for scale up when the cloudwatch alarm gets triggered.
resource "aws_appautoscaling_policy" "policy_scale_up" {
  count              = "${length(var.autoscale) > 0 ? 1 : 0}"
  name               = "${local.scale_up_name}"
  resource_id        = "${aws_appautoscaling_target.ecs_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "${lookup(var.autoscale, "adjustment_type")}"
    cooldown                = "${lookup(var.autoscale, "cooldown")}"
    metric_aggregation_type = "${lookup(var.autoscale, "aggregation_type", "Average")}"

    step_adjustment {
      metric_interval_lower_bound = "${lookup(var.autoscale, "scale_up_interval_lower_bound", "1")}"
      scaling_adjustment          = "${lookup(var.autoscale, "scale_up_adjustment")}"
    }
  }
}


