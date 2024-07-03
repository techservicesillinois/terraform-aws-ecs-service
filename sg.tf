# Security groups are only created for ECS services running in
# awsvpc mode (i.e. launch_type FARGATE or EC2)

locals {
  lb_sg_id = try(var.load_balancer.security_group_id != null, false) ? var.load_balancer.security_group_id : one(data.aws_security_group.lb.*.id)
}

# Default security group for the ECS service (awsvpc mode only)
resource "aws_security_group" "default" {
  count       = var.task_definition.network_mode == "awsvpc" ? 1 : 0
  description = format("%s ECS service", var.name)
  name        = var.name
  vpc_id      = data.aws_subnet.selected[0].vpc_id

  tags = local.tags

  lifecycle {
    ignore_changes = [description]
  }
}

# Allow outbound traffic from the LB to the containers
resource "aws_security_group_rule" "lb_out" {
  count       = var.task_definition.network_mode == "awsvpc" && var.load_balancer != null ? 1 : 0
  description = "Allow outbound connections from the LB to ECS service ${var.name}"

  type              = "egress"
  from_port         = var.load_balancer.container_port
  to_port           = var.load_balancer.container_port
  protocol          = "tcp"
  security_group_id = local.lb_sg_id

  source_security_group_id = aws_security_group.default[0].id
}

# Allow the containers to receive traffic from the LB
resource "aws_security_group_rule" "service_in_lb" {
  count       = var.task_definition.network_mode == "awsvpc" && var.load_balancer != null ? 1 : 0
  description = "Allow inbound TCP connections from the LB to ECS service ${var.name}"

  type                     = "ingress"
  from_port                = var.load_balancer.container_port
  to_port                  = var.load_balancer.container_port
  protocol                 = "tcp"
  source_security_group_id = local.lb_sg_id

  security_group_id = aws_security_group.default[0].id
}

# This security group rule opens the containers themselves to direct
# communication. This is mostly for testing. Avoid in prod. This
# rule is conditionally created if the ports var is populated.
resource "aws_security_group_rule" "service_in" {
  # BUG: THE COUNT LINE IS A HACK TO WORK AROUND A TERRAFORM BUG...
  count       = var.task_definition.network_mode == "awsvpc" ? length(var.network_configuration.ports) : 0
  description = "Allow inbound TCP connections directly to ECS service ${var.name}"

  type        = "ingress"
  from_port   = element(var.network_configuration.ports, count.index)
  to_port     = element(var.network_configuration.ports, count.index)
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.default[0].id
}

# Allows all inbound ICMP to support ping, traceroute, and most importantly Path MTU Discovery
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-ingress.html
# https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
resource "aws_security_group_rule" "service_icmp" {
  count       = var.task_definition.network_mode == "awsvpc" ? 1 : 0
  description = "Allow inbound ICMP traffic directly to ECS service ${var.name}"

  type        = "ingress"
  from_port   = -1 # Allow any ICMP type number
  to_port     = -1 # Allow any ICMP code
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.default[0].id
}

# Allow all outbound traffic from the containers. This is necessary
# to support pulling Docker images from Dockerhub and ECR. Ideally
# we would restrict outbound traffic to the LB and DB for CRUD apps.
resource "aws_security_group_rule" "service_out" {
  count       = var.task_definition.network_mode == "awsvpc" ? 1 : 0
  description = "Allow outbound connections for all protocols and all ports for ECS service ${var.name}"

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.default[0].id
}
