# A task definition is created if the user does not specify a task
# definition arn. The task definition map is used to customize the
# task definition created.
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html

# The cpu and memory values define the TOTAL cpu and memory resources
# reserved for all the containers defined in the container definition
# file; individual container cpu and memory sizes are defined in
# the task's container definition file. These values must not exceed
# the TOTAL set here.
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size

locals {
  task_definition_arn = "${element(concat(aws_ecs_task_definition.fargate.*.arn,
                           aws_ecs_task_definition.ec2.*.arn,  list("")), 0)}"
}

resource "aws_ecs_task_definition" "fargate" {
  count = "${var.task_definition_arn == "" && var.launch_type == "FARGATE" ? 1 : 0}"

  family                = "${var.name}"
  container_definitions = "${file(local.container_definition_file)}"
  task_role_arn         = "${local.task_role_arn}"
  execution_role_arn    = "${format("arn:aws:iam::%s:role/ecsTaskExecutionRole",
                                 data.aws_caller_identity.current.account_id)}"

  network_mode = "${local.network_mode}"
  volume       = "${var.volume}"

  cpu                      = "${local.cpu}"
  memory                   = "${local.memory}"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_task_definition" "ec2" {
  count = "${var.task_definition_arn == "" && var.launch_type == "EC2" ? 1 : 0}"

  family                = "${var.name}"
  container_definitions = "${file(local.container_definition_file)}"
  task_role_arn         = "${local.task_role_arn}"
  execution_role_arn    = "${format("arn:aws:iam::%s:role/ecsTaskExecutionRole",
                                 data.aws_caller_identity.current.account_id)}"

  network_mode = "${local.network_mode}"
  volume       = "${var.volume}"

  requires_compatibilities = ["EC2"]
}
