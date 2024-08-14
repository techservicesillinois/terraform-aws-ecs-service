# ecs-service

[![Terraform actions status](https://github.com/techservicesillinois/terraform-aws-ecs-service/workflows/terraform/badge.svg)](https://github.com/techservicesillinois/terraform-aws-ecs-service/actions)

Provides a service running under the Amazon Elastic Container Service (ECS). An ECS service is essentially a task such as a web service that is expected to run until terminated. ECS is normally configured to automatically restart a failed task.

ECS allows users to run Docker applications across a cluster of EC2 instances which provide compute power for the workload. Although running Docker containers is itself a straightforward process, configuration of the various infrastructure components (including integrating the containers with an optional application load balancer) is complex.

This module's primary intent is to simplify setting up load-balanced services using a shared
[application load balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html).
The module also supports running tasks in non-load-balanced containers in addition to supporting public and private application load balancers (ALBs).

ECS supports two launch types. The ECS launch type runs containerized services on a customer-managed ECS cluster. The Fargate launch type uses an Amazon-managed cluster that allows customers to run containers without having to manage a cluster of their own.

If using a load balancer, the module will create a
[listener rule](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-update-rules.html), a [target group](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html),
and [security groups](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_SecurityGroups.html) when in `awsvpc` mode.
In addition, the module will create a task definition
if one is not supplied by the caller.

This module does **not** support Amazon's
[classic load balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/introduction.html)
or
[network load balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html).

For more details, see the [ECS Services section in Amazon's ECS developer guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html).

Example Usage
-----------------

### Simple Fargate service on a public subnet
```hcl
module "service_name" {
  source = "git@github.com:techservicesillinois/terraform-aws-ecs-service//"

  name = "service_name"

  load_balancer = {
    name           = "load_balancer_name"
    port           = 443
    container_name = "main_container_name"
    container_port = 8080
    host_header    = "myservice.example.com"
  }

  alias = {
    domain   = "example.com"
    hostname = "myservice"
  }

  network_configuration = {
    assign_public_ip = true
    subnet_type      = "public"
    vpc              = "my-vpc"
  }
}
```

### Simple Fargate service on a private subnet with service discovery
```hcl
module "service_name" {
  source = "git@github.com:techservicesillinois/terraform-aws-ecs-service//"

  name  = "service_name"

  service_discovery = {
    namespace_id = "ns-cxn6fqejoygbxan5"
  }

  network_configuration = {
    subnet_type = "private"
    vpc         = "my-vpc"
  }
}
```


### Simple ECS service in bridge mode
```hcl
module "service_name" {
  source = "git@github.com:techservicesillinois/terraform-aws-ecs-service//"

  name        = "service_name"
  launch_type = "EC2"

  load_balancer = {
    name           = "load_balancer_name"
    port           = 443
    container_name = "main_container_name"
    container_port = 8080
    host_header    = "myservice.example.com"
  }

  alias = {
    domain   = "example.com"
    hostname = "myservice"
  }

  task_definition = {
    network_mode = "bridge"
  }
}
```

### ECS service using an externally defined task definition
```hcl
module "service_name" {
  source = "git@github.com:techservicesillinois/terraform-aws-ecs-service//"

  name                = "service_name"
  cluster             = "cluster_name"
  launch_type         = "EC2"

  task_definition_arn = "task_definition_name:revision"
  desired_count       = 3

  load_balancer = {
    name           = "load_balancer_name"
    port           = 443
    container_name = "main_container_name"
    container_port = 8080
    host_header    = "myservice.example.com"
  }

  alias = {
    domain   = "example.com"
    hostname = "myservice"
  }

  ordered_placement_strategy = [
    {
      type  = "binpack"
      field = "cpu"
    }
  ]

  placement_constraints = [
    {
      type       = "memberOf"
      expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
    }
  ]
}
```

Argument Reference
-----------------

The following arguments are supported:

* `alias` – (Optional) An [alias](#alias) block used to define a Route 53 alias record
that points to the load balancer. Requires that a `load_balancer` block is definied.

* `autoscale` – (Optional) An [autoscale](#autoscale) block is a complex data structure used to create an autoscaling configuration. Learn more about [ECS autoscaling](https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html). If no `autoscale` block is defined, no autoscaling takes place.

* `cluster` - (Optional) ECS cluster name. Defaults to `default`.

* `deployment_maximum_percent` - (Optional) The upper limit, as a percentage of the service's desired_count, of the number of running tasks that can be running in a service during a deployment.

* `deployment_minimum_healthy_percent` - (Optional) The lower limit, as a percentage of the service's `desired_count`, of the number of running tasks that must remain running and healthy in a service during a deployment

* `desired_count` - (Optional) The number of instances of the task
definition to place and keep running. Defaults to 1.

* `force_new_deployment` - (Optional) Enable forcing a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g., `myimage:latest`), roll Fargate tasks onto a newer platform version, or immediately deploy `ordered_placement_strategy` and `placement_constraints` updates.

* `health_check` -  (Optional) A [health check block](#health_check).
Health check blocks are documented below.

* `health_check_grace_period_seconds` - (Optional) Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 1800. Only valid for services configured to use load balancers.

* `launch_type` - (Optional) Launch type for the service. Valid values are EC2 and FARGATE. Defaults to FARGATE.

* `load_balancer` - (Optional) A [load balancer block](#load_balancer).
Load balancer blocks are documented below.

* `name` - (Required) ECS service name. Up to 255 letters (uppercase and lowercase), numbers, hyphens, and underscores are allowed.

* `network_configuration` - (Optional) A [network configuration](#network_configuration) block is required for task definitions using the `awsvpc` network mode, in order that those tasks receive an [Elastic Network Interface](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html). The `network_configuration` block is **not**
supported for other network modes.

* `ordered_placement_strategy` - (Optional) This variable is a list of strategy rules taken into consideration during task placement, in descending order of precedence. Not compatible with the FARGATE launch type. See the description of the [`ordered_placement_strategy`](#ordered_placement_strategy) block below.

* `placement_constraints` - (Optional) Rules taken into consideration during task placement. Not compatible with the FARGATE launch type. The [`placement_constraints`](#placement_constraints) block is defined below.

* `platform_version` - (Optional) Platform version for FARGATE launch type. Not compatible with other launch types.

* `propagate_tags` - (Optional) Whether to propagate the tags from the task definition or the service to the tasks. May contain values `NONE`, `SERVICE`, `TASK_DEFINITION`. The default is `TASK_DEFINITION`.

* `service_discovery` - (Optional) A [service discovery](#service_discovery) block.
This parameter is used to configure
[Amazon Service Discovery](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html) for the service.

* `task_definition` - (Optional) The [task definition](#task_definition) block defines characteristics like CPU and memory for deploying Docker containers in Amazon ECS. See also [Amazon ECS task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html).

* `task_definition_arn` - (Optional) An existing task definition, either in the format `family:revision`, or the full ARN to run with your service. If this variable is defined, the `task_definition` block is ignored.

* `stickiness` - (Optional) If specified, the [`stickiness`](#stickiness) block causes the load balancer to bind client requests to the same target. Valid only with application load balancers. Not valid without an application load balancer.

* `tags` - Tags to be applied to resources where supported.

* `volume` - (Optional) List of objects defining which Docker or EFS volumes are available to containers The [`volume`](#volume) block is documented below.

### Debugging

* `_debug` - (Optional) If set, produce verbose output for debugging.

`alias`
-------

An `alias` block supports the following:

* `domain` - (Required) The name of the Route 53 zone in which the alias record
is to be created.

* `hostname` – (Optional) The name of the host to be created in the specified Route
53 zone. Defaults to the value of the `name` attribute (i.e., the service name).

`autoscale`
----------

An `autoscale` block is a nested data structure that defines whether the container deployment supports autoscaling, and defines the scaling behavior. This module manages the application autoscaling target, CloudWatch metric alarms, and autoscaling policies required to configure an autoscaling application.

[Service autoscaling](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html) for Amazon ECS is an advanced topic.

### Configure autoscaling for ECS

> **NOTE:** The example autoscaling block below is wrapped inside the Terraform `module` block that invokes this module. This outer wrapper is omitted in this example for clarity.

```hcl
  autoscale = {
    max_capacity = 5
    min_capacity = 1
    metrics = {
      CPUUtilization = {
        adjustment_type         = "ChangeInCapacity"
        datapoints_to_alarm     = 1
        evaluation_periods      = 1
        metric_aggregation_type = "Average"
        period                  = 60
        statistic               = "Average"

        down = {
          comparison_operator         = "LessThanThreshold"
          cooldown                    = 180
          metric_interval_upper_bound = 0
          scaling_adjustment          = -1
          threshold                   = 40
        }

        up = {
          comparison_operator         = "GreaterThanOrEqualToThreshold"
          cooldown                    = 60
          metric_interval_lower_bound = 1
          scaling_adjustment          = 1
          threshold                   = 70
        }
      }
```

The top-level `autoscale` object consists of three input arguments used to configure the application autoscaling target:

* `max_capacity` - (Required) Specifies the maximum capacity, namely the largest number of tasks that ECS will deploy. A value of `5` means that ECS will scale up to no more than five tasks.

* `min_capacity` - (Required) Specifies the minimum capacity, namely the largest number of tasks that ECS will deploy. A value of `2` means that ECS will scale down to no fewer than two tasks.

* `metrics` - (Required) A map of [autoscaling metrics](#autoscalemetrics). Each entry in this map consists of a key specifying an autoscaling metric. See [Amazon ECS CloudWatch metrics](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-metrics.html#service_utilization). The value stored under each key in the `metrics` sub-object is itself another sub-object that defines how the specified metric is evaluated by ECS.

> **NOTE:** At this time, this module is limited to autoscaling on only the two CloudWatch metrics `CPUUtilization` and `MemoryUtilization` defined in the `AWS/ECS` namespace. As a result, the dimensions `ClusterName` and `ServiceName` associated with that namespace are "hardwired" into this module. This restriction will be eliminated in a future version of this module, although that will require an even deeper data structure.

`autoscale.metrics`
-------------------

Each autoscaling `metrics` sub-object allows specifying the following arguments:

* `actions_enabled` - (Optional) Indicates whether or not actions should be executed during any changes to the alarm's state. Defaults to `true`.

* `adjustment_type` - (Required) Whether the adjustment is an absolute number or a percentage of the current capacity.

* `datapoints_to_alarm` -  - (Optional) The number of datapoints that must be breaching the threshold to trigger the alarm.

* `evaluation_periods` - (Required) The number of periods over which data is compared to the specified threshold.

* `metric_aggregation_type` - (Optional) Aggregation type for the policy's metrics. In the absence of a value, AWS treats the aggregation type as "Average".

* `period` - (Required) The period in seconds over which the specified statistic is applied.

* `statistic` - (Required) The statistic (e.g., `Average`) to apply to the alarm's associated metric.

* `down` - (Required) An object defining behavior for a scale-down alarm. See [`autoscale.metrics.down` and `autoscale.metrics.up`](#autoscalemetricsdown-and-autoscalemetricsup).

* `up` - (Required) An object defining behavior for a scale-up alarm. See [`autoscale.metrics.down` and `autoscale.metrics.up`](#autoscalemetricsdown-and-autoscalemetricsup).

`autoscale.metrics.down` and `autoscale.metrics.up`
---------------------------------------------------

The `autoscale.metrics.down` and `autoscale.metrics.up` sub-objects use the same input variables, albeit for scaling down and scaling up, respectively.

* `comparison_operator` - (Required) The arithmetic operation to use when comparing the statistic and threshold.

* `cooldown` - (Optional) Amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start.

* `metric_interval_lower_bound` - (Optional) Lower bound for the difference between the alarm threshold and the CloudWatch metric. Without a value, AWS will treat this bound as negative infinity.

* `metric_interval_upper_bound` - (Optional) Upper bound for the difference between the alarm threshold and the CloudWatch metric. Without a value, AWS will treat this bound as infinity. The upper bound must be greater than the lower bound.

* `scaling_adjustment` - (Required) Number of members by which to scale, when the adjustment bounds are breached. A positive value scales up. A negative value scales down.

* `threshold` - (Required) The value against which the specified statistic is compared.

`health_check`
-----------------

A `health_check` block supports the following:

* `enabled` - (Optional) Whether health checks are enabled. Defaults to `true`.

* `healthy_threshold` - (Optional) The number of consecutive health
checks successes required before considering an unhealthy target
healthy.

* `interval` - (Optional) The approximate amount of time, in seconds,
between health checks of an individual target.

* `matcher` - (Optional) The HTTP codes to use when checking for a
successful response from a target. You can specify multiple values
(for example, "200,202") or a range of values (for example, "200-299").

* `path` - (Optional) The destination for the health check request. Defaults to `/`.

* `port` - (Optional) The port to use to connect with the target.
Valid values are either ports 1-65536, or `container_port`. Defaults
to `container_port`.

* `protocol` - (Optional) The protocol to use to connect with the
target. Defaults to HTTP.

* `timeout` - (Optional) The amount of time, in seconds, during which
no response means a failed health check.

* `unhealthy_threshold` - (Optional) The number of consecutive health
check failures required before considering the target unhealthy.

`load_balancer`
-----------------

A `load_balancer` block may contain the following inputs:

* `certificate_domain` - (Optional) The domain name associated with an Amazon Certificate Manager (ACM) certificate. If specified, the certificate is looked up by the domain name, and the resulting certificate is associated with the listener for the ECS service.

* `container_name` - (Required) The name of the container to associate with the load balancer as specified in the container definition (`containers.json` by default).

* `container_port` - (Required) The port on the container to associate with the load balancer as specified in the container definition (`containers.json` by default).

* `deregistration_delay` - (Optional) The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused.

* `host_header` - (Required) A [hostname condition](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#host-conditions)
that defines a rule to forward requests to the service's target group.

* `manage_listener_certificate` - (Optional) This Boolean argument specifies whether a listener certificate should be managed with the ECS task. This is `true` by default. Normally, listener certificates can have the same lifecycle as the ECS task and the listener used by the load balancer to route traffic to the appropriate ECS task.

    However, cases exist where more then one ECS task listens on the same `host_header`. These tasks use `path_pattern` and `priority` to distinguish which task handles a particular request. In this case, it is advisable to create a `listener_certificate` in a separate directory, allowing that listener certificate to persist longer than any of the individual ECS tasks. The `manage_listener_certificate` is set to `false` in this case, so that the destruction of one ECS task for maintenance doesn't delete the listener certificate that other tasks depend upon.

    In these cases, use the [terraform-aws-lb-listener-certificate](https://github.com/techservicesillinois/terraform-aws-lb-listener-certificate) module in a separate directory to maintain that listener certificate independently of the tasks that use that listener certificate.

    For example:

    ```
    ./
    ├── acm/
    │   └── terragrunt.hcl
    ├── apps/
    │   ├── common.tfvars
    │   ├── bar/
    │   │   ├── containers.json.tftpl
    │   │   └── terragrunt.hcl
    │   └── foo/
    │       ├── containers.json.tftpl
    │       └── terragrunt.hcl
    └── listener-cert/
        └── terragrunt.hcl
```

* `name` - (Required) The name of the load balancer.

* `path_pattern` - (Optional) A [path condition](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#path-conditions)
that defines a rule to forward requests based on the URL path.
Defaults to `*`.

* `port` - (Optional) The port of the listener. Defaults to 443.

* `priority` - (Optional) The priority for the rule between 1 and 50000. Leaving it unset will automatically set the rule with next available priority after currently existing highest rule. A listener can't have multiple rules with the same priority.

* `security_group_id` - (Optional) The security group ARN associated with the lLoad lalancer. If not specified it is looked up by the load balancer's name.

> **NOTE:** No more than one load balancer may be attached to an ECS service. See the AWS [Service load balancing](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html#load-balancing-concepts) documentation.

`network_configuration`
-----------------------

A `network_configuration` block supports the following:

* `assign_public_ip` - (Optional) Boolean value specifies whether a public IP address to the Elastic Network Interface (FARGATE launch type only) is created. Default is `false`.

* `ports` - (Optional) A list of numeric ports to open on the container to outside traffic. (**NOTE:** This is insecure, and is intended to be used *only* for testing FARGATE.)

* `security_group_ids` - (Optional) A list of security group IDs to associate with
the task or service. If used with `security_group_names`, the security groups consist of the union of the security groups derived from both lists. **If you do not specify a security group, the VPC's default security group is used.**

* `security_group_names` - (Optional) A list of security group names to associate with the task or service. If used with `security_group_ids`, the security groups consist of the union of the security groups derived from both lists. **If you do not specify a security group, the VPC's default security group is used.**

* `subnet_ids` - (Optional) A list of subnet IDs in which the tasks or service will be placed. **NOTE:** Though optional, either `subnet_ids` or `subnet_type` are required, and both may be specified.

* `subnet_type` - (Optional) Specifies the type of subnet(s) in which the tasks or service will be placed. Valid values are 'campus', 'private', or 'public'. **NOTE:** Though optional, either `subnet_ids` or `subnet_type` are required, and both may be specified. If `subnet_type` is populated, a value for `vpc` must be specified.

* `vpc` - (Optional) The name of the virtual private cloud to be associated with the task or service. **NOTE:** Required when using `subnet_type`.

For more information, see the AWS [Task Networking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html) documentation.

> NOTE: `network_configuration` is only supported when `network_mode` is `awsvpc`.

> NOTE: The `subnet_id` and `subnet_type` attributes can be used together. In this case the subnets to be associated with the service consist of the union of the subnets IDs defined explicitly in `subnet` and the subnet IDs derived from `subnet_type` and `vpc`.

`ordered_placement_strategy`
---------------------------

`ordered_placement_strategy` blocks support the following:

* `field` - (Optional) For the `spread` placement strategy, valid values
are `instanceId` (or `host`, which has the same effect), or any platform
or custom attribute that is applied to a container instance. For
the `binpack` type, valid values are `memory` and `cpu`. For the `random`
type, this attribute is not needed. For more information, see
[Placement Strategy](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PlacementStrategy.html).

* `type` - (Required) The type of placement strategy. Must be one
of: `binpack`, `random`, or `spread`.

> NOTE: `ordered_placement_strategy` is not supported when `launch_type` is FARGATE.

> NOTE: for `spread`, the `host` and `instanceId` will be normalized, by AWS, to be `instanceId`. This means the state file will show `instanceId` but your Terraform will observe differences if you use `host`.

`placement_constraints`
-----------------------

`placement_constraints` blocks support the following:

* `expression` - (Optional) Cluster Query Language expression to apply
to the constraint. Does not need to be specified for the `distinctInstance`
type. For more information, see [Cluster Query Language in the Amazon
EC2 Container Service Developer Guide.](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html).

* `type` - (Required) The type of constraint. The only valid values at
this time are `memberOf` and `distinctInstance`.

> NOTE: `placement_constraints` is not supported when `launch_type` is FARGATE.

`service_discovery`
-----------------

A `service_discovery` block configures [Amazon Service Discovery](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html) and supports the following arguments:

* `dns_routing_policy` – (Optional) The routing policy that you want to apply to all records that Route 53 creates when you register an instance and specify the service. Valid values are MULTIVALUE, and WEIGHTED.

* `dns_ttl` – (Optional) The amount of time, in seconds, that you want DNS resolvers to cache the settings for this resource record set. Default is 60 seconds.

* `dns_type` – (Optional) The type of the resource, which indicates the value that Amazon Route 53 returns in response to DNS queries. Valid values are: A, AAAA, CNAME, and SRV. Default is "A".

* `health_check_config` – (Optional) A [service discovery health check config](#service_discoveryhealth_check_config) block that contains settings for an
optional health check. Only supported with public DNS namespaces.

* `name` – (Optional) The hostname of the service. Defaults to the service name specified
 by the `name` argument.

* `namespace_id` – (Required) The ID of the namespace to use for DNS configuration.
* `service_discovery_health_check_custom_config` – (Optional) A [service discovery
custom health check config](#service_discoveryhealth_check_custom_config) block that
contains settings for ECS-managed health checks.

`service_discovery.health_check_config`
---------------------------------------

The following arguments are supported by this sub-object:

* `failure_threshold` – (Optional) The number of consecutive failed health checks to constitute unhealthiness.

* `resource_path` – (Optional) A path that Route 53 will request when performing health checks. Route 53 automatically adds the DNS name for the service. If you don't specify a value, the default value is `/`.

* `type` – (Optional) The type of health check that you want to create, which indicates how Route 53 determines whether an endpoint is healthy. Valid values are HTTP, HTTPS, and TCP.

`service_discovery.health_check_custom_config`
----------------------------------------------

The following argument is supported by this sub-object:

* `failure_threshold` – (Optional) The number health check intervals that service discovery should wait before it marks a service instance as unhealthy.

`stickiness`
-----------------

A `stickiness` block supports the following arguments:

* `cookie_duration` - (Optional) The time period, in seconds, during
which requests from a client should be routed to the same target.
After this time period expires, the load balancer-generated cookie
is considered stale.

* `enabled` - (Optional) Boolean value determining whether sessions are sticky.
Default is `false`.

* `type` - (Required) The type of sticky sessions. The only current
possible value is `lb_cookie`.

`task_definition`
-----------------

If a `task_definition_arn` is not given, a container definition will be created for the service. The name of the automatically created container definition is the same as the ECS service name.
The created container definition may optionally be further modified by specifying a `task_definition` block with one of more of the following options:

* `container_definition_file` - (Optional) An ECS service that does *not* use an existing task definition requires specifying
characteristics for the set of containers that will comprise the service.
This configuration is defined in the file specified in the `container_definition_file` argument, and consists of a list of valid [container
definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions) provided as a valid JSON document.
See
[Example Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/example_task_definitions.html) for example container definitions.

    Note that _only_ the content of the `containerDefinitions` key
in these example task definitions belongs in the specified `container_definition_file`.
The default filename is either `containers.json.tftmpl` or `containers.json`. More details can be found at the end of this section.

* `cpu` - (Optional) The number of
[cpu units](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) used by the task.
Supported for FARGATE only.

* `memory` - (Optional) The amount (in MiB) of
[memory](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) used by the task.
Supported for FARGATE only.

* `network_mode` - (Optional) The Docker networking mode to use for
containers in the task. The valid values are `none`, `bridge`,
`awsvpc`, and `host`.

* `task_role_arn` - (Optional) The ARN of an IAM role that allows
your Amazon ECS container task to make calls to other AWS services.

* `template_variables` - (Optional) A block of template variables to be expanded while processing the `container_definition_file`. Used to configure [template variables](#task_definitiontemplate_variables) passed to the task definition.

`task_definition.template_variables`
------------------------------------

This block itself is optional. However, if the block is defined by the caller, *all* of the following arguments must be specified. The arguments supported by this sub-object are as follows:

* `docker_tag` - (Required) The Docker tag for the image that is to be pulled from the ECR repository at the time the service's ECS tasks are launched.

* `region` - (Required) The AWS region which hosts the ECR repository from which images are to be pulled.

* `registry_id` - (Required) The registry ID is the AWS account number which owns the repository to be pulled at the time the service's ECS task is launched.

### Notes on the `container_definition_file` argument

If the `task_definition` block is defined, and its `template_variables` block is populated, this module runs the Terraform [`templatefile()`](https://developer.hashicorp.com/terraform/language/functions/templatefile) function on the file named in the `container_definition_file` argument. By default, the file name is `containers.json.tftmpl`, but it can be overriden by the user.
The output from the template's rendering is passed to the task definition.

The use of template variables helps make the Terraform configuration DRY by eliminating the need for manual editing – such as during the promotion of services from test to production accounts.
The example below shows how template variables `docker_tag`, `region`, and `registry_id` are passed to the task definition when template rendering is requested by the caller using the `template_variables` block and an appropriately-configured `containers.json.tftmpl` file.

### A `containers.json.tftmpl` file supports template rendering

This example uses all of the supported template variables. The construct `${variable_name}` to expand a supported template variable.

```json
[
  {
    "name": "daemon",
    "image": "${registry_id}.dkr.ecr.${region}.amazonaws.com/foobar:${docker_tag}",
    "logConfiguration": {
       "logDriver": "awslogs",
       "options": {
         "awslogs-stream-prefix": "foobar",
         "awslogs-group": "/service/foobar",
         "awslogs-region": "${region}"
      }
    }
  }
]
```

If a container definition is needed without the templating capability of this module, omit  the `template_variables` block of the `task_definition` block. The default file name is `containers.json`, which can be overriden by the user. In this case, the container definition is passed in to the task definition verbatim, as in the following example.

### A `containers.json` file does not support template rendering

```json
[
  {
    "name": "apache",
    "image": "httpd",
    "portMappings": [
      {
        "containerPort": 80
      }
    ]
  }
]

```

`volume`
--------

A `volume` block supports the following arguments:

* `docker_volume_configuration` - (Optional) Used to configure a [Docker volume](#volumedocker_volume_configuration). **NOTE:** Due to limitations in Terraform object typing, either a valid `docker_volume_configuration` object or a `null` must be specified whenever a `volume` block is defined.

* `efs_volume_configuration` - (Optional) Used to configure an [EFS volume](#volumeefs_volume_configuration). **NOTE:** Due to limitations in Terraform object typing, either a valid `efs_volume_configuration` object or `null` must be specified whenever a `volume` block is defined.

* `host_path` - (Optional) The path on the host container instance presented to the container.
If not set, ECS will create a non-persistent data volume that starts empty, and which is deleted after the task exits.

* `name` - (Required) The volume name. This value is referenced in the `sourceVolume` parameter of the container definition inside the `mountPoints` configuration.

```
volume = [
    {
      name      = "docker-volume"
      host_path = null

      docker_volume_configuration = null   # Needs to be specified as null, even if not used.
      efs_volume_configuration    = null   # Needs to be specified as null, even if not used.
    }
 ]
```

`docker_volume_configuration`
--------

A `docker_volume_configuration` block appears within a [`volume`](#volume) block, and supports the following:

* `autoprovision` - (Optional) If this value is true, the Docker volume is created if it does not already exist. Note: This field is only used if the scope is shared.

* `driver` - (Optional) The Docker volume driver to use. The driver value must match the driver name provided by Docker because it is used for task placement.

* `driver_opts` - (Optional) A map of Docker driver specific options.

* `labels - (Optional) A map of custom metadata to add to your Docker volume.

* `scope` - (Optional) The scope for the Docker volume, which determines its lifecycle, which is either `task` or `shared`. Docker volumes that have `task` scope are automatically provisioned when the task starts, and are destroyed when the task stops.
Docker volumes that are scoped as `shared` persist after the task stops.

For more information, see [Specifying a Docker volume in your Task Definition Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-volumes.html#specify-volume-config)

`efs_volume_configuration`
--------

An `efs_volume_configuration` block appears within a [`volume`](#volume) block, and supports the following:

* `file_system_id` - (Required) The ID of the EFS file system.

* `root_directory` - (Optional) The path to mount on the host.

```
volume = [
    {
      name = "efs-volume"
      host_path = null

      docker_volume_configuration = null

      efs_volume_configuration = {
        file_system_id = "fs-012345678"
        root_directory = null
      }
    }
 ]
```

For more information, see [Specifying an Amazon EFS File System in your Task Definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html#specify-efs-config).

Attributes Reference
--------------------

The following attributes are exported:

* `autoscaling_alarm` - This output is a map of maps. The outer keys are `down` and `up`, which correspond to scale-down and scale-up activity. The value stored under each such key is another map. The key for each entry in this inner map is the name of the CloudWatch metric associated with the alarm, with the ARN of the alarm as the corresponding value.

* `autoscaling_policy` - This output is a map of maps. The outer keys are `down` and `up`, which correspond to scale-down and scale-up activity. The value stored under each such key is another map. The key for each entry in this inner map is the name of the CloudWatch metric associated with the policy, with the ARN of the policy as the corresponding value.

* `fqdn` – The fully qualified domain name of the Route 53 record for
the service. Only created when an `alias` block is specified.

* `id` - The Amazon Resource Name (ARN) that identifies the ECS service.

* `security_group_id` - The ID of the security group created for the service (`awsvpc` mode only).

* `service_discovery_registry_arn` - The ARN of the service discovery registry associated with the service, if any.

* `subnet_ids` – A list of subnet IDs associated with the service.

* `target_group_arn` - The ARN of the target group created when a
`load_balancer` block is specified.

* `task_definition_arn` - Full ARN of the task definition created
for the service when a `task_definition_arn` is not given.

For additional outputs produced when the `_debug` argument is set, please see the source code.

Credits
--------------------

**Nota bene:** The vast majority of the verbiage on this page was
taken directly from the Terraform manual, and in a few cases from
Amazon's documentation.
