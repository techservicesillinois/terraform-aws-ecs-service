resource "aws_cloudwatch_event_rule" "default" {
  name                = "${var.scheduled_task}"
  schedule_expression = "${var.scheduled_task_expression}"
  is_enabled          = "${var.scheduled_task_enabled}"
}

resource "aws_cloudwatch_event_target" "default" {
  target_id = "${var.scheduled_task_target}"
  rule      = "${aws_cloudwatch_event_rule.default.name}"
  arn       = "${var.scheduled_task_target_arn}"
  role_arn  = "${aws_iam_role.ecs_events_role.arn}"

  ecs_target {
    task_count          = "${var.desired_count}"
    task_definition_arn = "${var.task_definition_arn}"
    launch_type = "${var.launch_type}"
    network_configuration {
      subnets = ["${data.aws_subnet_ids.selected.*.ids}"]
    }
  }
}


# iam
resource "aws_iam_role" "ecs_events_role" {
  name               = "${var.scheduled_task}-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_events_policy.json}"
}

resource "aws_iam_role_policy_attachment" "events_service_role_attachment" {
  role       = "${aws_iam_role.ecs_events_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}


data "aws_iam_policy_document" "ecs_events_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}
