# Security groups are only created for ECS services running in
# awsvpc mode (i.e. launch_type FARGATE or EC2)

locals {
  lb_sg_id = length(local.lb_security_group_id) > 0 ? local.lb_security_group_id : element(concat(data.aws_security_group.lb.*.id, [""]), 0)
}

# Allow the LB to send packets to the containers
resource "aws_security_group_rule" "lb_out" {
  # count        = local.network_mode == "awsvpc" && length(var.load_balancer) > 0 ? 1 : 0
  count       = local.uses_alb && local.network_mode == "awsvpc" && length(var.load_balancer) > 0 ? 1 : 0
  description = "Allow outbound connections from the LB to ECS service ${var.name}"

  type              = "egress"
  from_port         = local.container_port
  to_port           = local.container_port
  protocol          = "tcp"
  security_group_id = local.lb_sg_id

  source_security_group_id = aws_security_group.default[0].id
}

# Default security group for the ECS service (awsvpc mode only)
resource "aws_security_group" "default" {
  # count       = local.network_mode == "awsvpc" ? 1 : 0
  count       = local.uses_alb && local.network_mode == "awsvpc" ? 1 : 0
  description = "security group for ${var.name} service"
  name        = var.name
  vpc_id      = data.aws_subnet.selected[0].vpc_id

  tags = merge({ "Name" = var.name }, var.tags)
}

# Allow the containers to receive packets from the LB
resource "aws_security_group_rule" "service_in_lb" {
  # count       = local.network_mode == "awsvpc" && length(var.load_balancer) > 0 ? 1 : 0
  count       = local.uses_alb && local.network_mode == "awsvpc" && length(var.load_balancer) > 0 ? 1 : 0
  description = "Allow inbound TCP connections from the LB to ECS service ${var.name}"

  type                     = "ingress"
  from_port                = local.container_port
  to_port                  = local.container_port
  protocol                 = "tcp"
  source_security_group_id = local.lb_sg_id

  security_group_id = aws_security_group.default[0].id
}

# This security group rule opens the containers themselves to direct
# communication. This is mostly for testing. Avoid in prod. This
# rule is conditionally created if the ports var is populated.
resource "aws_security_group_rule" "service_in" {
  # BUG: THE COUNT LINE IS A HACK TO WORK AROUND A TERRAFORM BUG...
  # count       = local.network_mode == "awsvpc" ? length(local.ports) : 0
  count       = local.uses_alb && local.network_mode == "awsvpc" ? length(local.ports) : 0
  description = "Allow inbound TCP connections directly to ECS service ${var.name}"

  type        = "ingress"
  from_port   = element(local.ports, count.index)
  to_port     = element(local.ports, count.index)
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.default[0].id
}

# Allows all inbound ICMP to support ping, traceroute, and most importantly Path MTU Discovery
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-ingress.html
# https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
resource "aws_security_group_rule" "service_icmp" {
  # count       = local.network_mode == "awsvpc" ? 1 : 0
  count       = local.uses_alb && local.network_mode == "awsvpc" ? 1 : 0
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
  # count       = local.network_mode == "awsvpc" ? 1 : 0
  count       = local.uses_alb && local.network_mode == "awsvpc" ? 1 : 0
  description = "Allow outbound connections for all protocols and all ports for ECS service ${var.name}"

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.default[0].id
}
