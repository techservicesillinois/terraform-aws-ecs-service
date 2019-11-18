Feature: We are able to instantiate all aws_ecs_service resources
    Background: Start with ecs-service module
        Given the following variables
            | key              | value                              |
            #------------------|------------------------------------|
            | ecs service name | delete-me-behave-tf-$(RANDOM:10)   |
            | cluster          | behave-test                        |
        
        Given terraform module 'ecs-service'
            | varname | value                              |
            #---------|------------------------------------|
            | name    | "${var.ecs service name}"          |
            | cluster | "${var.cluster}"                   |
        
        Given terraform file 'containers.json'
            """
            [{
              "name": "apache",
              "image": "httpd",
              "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                  "awslogs-stream-prefix": "prod",
                  "awslogs-group": "example",
                  "awslogs-region": "us-east-2"
                }
              },
              "portMappings": [
                {
                  "containerPort": 80
                }
              ]
            }]
            """
    
    Scenario: Instance of 'aws_ecs_service' 'awsvpc_all'
              Additionally:
                (A) create 'aws_alb_listener_rule' 'set_priority'
                (B) create 'aws_route53_record' 'default'
                (C) create 'aws_security_group_rule' 'service_in'
                (D) create 'aws_service_discovery_service' 'health_check_custom'
        # (B)
        #Create aws_rout53_record default
        Given terraform map 'alias'
            | varname | value                               |
            #---------|-------------------------------------|
            | domain  | "as-test.techservices.illinois.edu" |
        
        Given terraform map 'load_balancer'
            | varname        | value                                              |
            #----------------|----------------------------------------------------|
            | name           | "public"                                           |
            | port           | "443"                                              |
            | container_name | "apache"                                           |
            | container_port | "80"                                               |
            | host_header    | "${var.ecs service name}.as-test.techservices.illinois.edu" |
            # (A)                                                                 |
            #NOTE: Priority has a chance of clashing with existing rule priorities.
            # Create aws_alb_listener_rule set_priority                           |
            | priority       | "30000"                                            |
        
        Given terraform map 'network_configuration'
            | varname          | value                     |
            #------------------|---------------------------|
            | security_group   | "default"                 |
            | vpc              | "techservicesastest2-vpc" |
            | tier             | "public"                  |
            | assign_public_ip | "true"                    |
            # (C)                                          |
            # Create aws_security_group_rule service_in    |
            # TODO: Perform curl on container IP (new step)|
            | ports            | "80"                      |
       
        Given terraform map 'service_discovery'
            | varname      | value                 |
            #--------------|-----------------------|
            | namespace_id | "ns-vf7wvzzwnp4d3rv2" |
        
        # (D)
        # Create aws_service_discovery_service health_check_custom
        Given terraform map 'service_discovery_health_check_custom_config'
            | varname           | value |
            #-------------------|-------|
            | failure_threshold | 1     |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "awsvpc"  |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                      | name                | count |
            #--------|-------------------------------|---------------------|-------|
            | create | aws_alb_listener_rule         | set_priority        |       |
            |        | aws_ecs_service               | awsvpc_all          |       |
            |        | aws_ecs_task_definition       | default             |       |
            |        | aws_lb_target_group           | default             |       |
            |        | aws_route53_record            | default             |       |
            |        | aws_security_group            | default             |       |
            |        | aws_security_group_rule       | lb_out              |       |
            |        | aws_security_group_rule       | service_icmp        |       |
            |        | aws_security_group_rule       | service_in_lb       |       |
            |        | aws_security_group_rule       | service_in          |       |
            |        | aws_security_group_rule       | service_out         |       |
            |        | aws_service_discovery_service | health_check_custom |       |
        
        When we run terraform apply
        
        Then aws ECS has services in a steady state
            |key       | value                   |
            #----------|-------------------------|
            | services | ${var.ecs service name} |
            | cluster  | ${var.cluster}          |
        # TODO
        # curl hostname if load balancer is configured
        # curl container IP if ports is set in the "network configuration" block
        # curl service-discovery hostname (would only work inside VPC) if "service discovery" block exists
           
#    @EC2
#    Scenario: Instance of 'aws_ecs_service' 'all'
#        Given terraform tfvars
#            | varname     | value |
#            #-------------|-------|
#            | launch_type | "EC2" |
#        
#        Given terraform map 'load_balancer'
#            | varname        | value                                              |
#            #----------------|----------------------------------------------------|
#            | name           | "private"                                          |
#            | port           | "80"                                               |
#            | container_name | "apache"                                           |
#            | container_port | "80"                                               |
#            | host_header    | "${var.ecs service name}.as-test.techservices.illinois.edu" |
#       
#        Given terraform map 'service_discovery'
#            | varname      | value                 |
#            #--------------|-----------------------|
#            | namespace_id | "ns-vf7wvzzwnp4d3rv2" |
#            | type         | "SRV"                 |
#        
#        Given terraform map 'task_definition'
#            | varname        | value     |
#            #----------------|-----------|
#            | network_mode   | "bridge"  |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                      | name    | count |
#            #--------|-------------------------------|---------|-------|
#            | create | aws_alb_listener_rule         | default |       |
#            |        | aws_ecs_service               | all     |       |
#            |        | aws_ecs_task_definition       | default |       |
#            |        | aws_lb_target_group           | default |       |
#            |        | aws_service_discovery_service | default |       |
#        
#        When we run terraform apply
#        
#        Then aws ECS has services in a steady state
#            |key       | value                   |
#            #----------|-------------------------|
#            | services | ${var.ecs service name} |
#            | cluster  | ${var.cluster}          |
#            | timeout  | 00:30                   |
    
    
    Scenario: Instance of 'aws_ecs_service' 'awsvpc'
        Given terraform map 'network_configuration'
            | varname          | value                     |
            #------------------|---------------------------|
            | security_group   | "default"                 |
            | vpc              | "techservicesastest2-vpc" |
            | tier             | "public"                  |
            | assign_public_ip | "true"                    |
            # TODO: curl container IP (after stabilization step)
            | ports            | "80"                      |
        
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            # Needed because there is no LB
            | container_name | "example" |
            | container_port | "80"      |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                | name         | count |
            #--------|-------------------------|--------------|-------|
            | create | aws_ecs_service         | awsvpc       |       |
            |        | aws_ecs_task_definition | default      |       |
            |        | aws_security_group      | default      |       |
            |        | aws_security_group_rule | service_in   |       |
            |        | aws_security_group_rule | service_out  |       |
            |        | aws_security_group_rule | service_icmp |       |
        
        When we run terraform apply
        
        Then aws ECS has services in a steady state
            |key       | value                   |
            #----------|-------------------------|
            | services | ${var.ecs service name} |
            | cluster  | ${var.cluster}          |
    
    
    Scenario: Instance of 'aws_ecs_service' 'awsvpc_lb'
        Given terraform map 'load_balancer'
            | varname        | value                                              |
            #----------------|----------------------------------------------------|
            | name           | "public"                                           |
            | port           | "443"                                              |
            | container_name | "apache"                                           |
            | container_port | "80"                                               |
            | host_header    | "${var.ecs service name}.as-test.techservices.illinois.edu" |
            
            # TODO: Add alias block OR curl with header host set to host_header
            #   IN ORDER TO test that the container is ACCESSIBLE
            #   Whether or not the container is WORKING is answered (well enough) by the stability test
        
        Given terraform map 'network_configuration'
            | varname          | value                     |
            #------------------|---------------------------|
            | security_group   | "default"                 |
            | vpc              | "techservicesastest2-vpc" |
            | tier             | "public"                  |
            | assign_public_ip | "true"                    |
       
        Given terraform map 'task_definition'
            | varname        | value     |
            #----------------|-----------|
            | network_mode   | "awsvpc"  |
        
        When we run terraform plan
        
        Then terraform plans to perform these exact resource actions
            | action | resource                | name          | count |
            #--------|-------------------------|---------------|-------|
            | create | aws_alb_listener_rule   | default       |       |
            |        | aws_ecs_service         | awsvpc_lb     |       |
            |        | aws_ecs_task_definition | default       |       |
            |        | aws_lb_target_group     | default       |       |
            |        | aws_security_group      | default       |       |
            |        | aws_security_group_rule | lb_out        |       |
            |        | aws_security_group_rule | service_icmp  |       |
            |        | aws_security_group_rule | service_in_lb |       |
            |        | aws_security_group_rule | service_out   |       |
        
        When we run terraform apply
        
        Then aws ECS has services in a steady state
            |key       | value                   |
            #----------|-------------------------|
            | services | ${var.ecs service name} |
            | cluster  | ${var.cluster}          |
    
#    @EC2
#    Scenario: Instance of 'aws_ecs_service' 'awsvpc_sd'
#        Given terraform map 'network_configuration'
#            | varname          | value                     |
#            #------------------|---------------------------|
#            | security_group   | "default"                 |
#            | vpc              | "techservicesastest2-vpc" |
#            | tier             | "public"                  |
#            | assign_public_ip | "true"                    |
#            # TODO: curl container IP
#            | ports            | "80"                      |
#       
#        Given terraform map 'service_discovery'
#            | varname      | value                 |
#            #--------------|-----------------------|
#            | namespace_id | "ns-vf7wvzzwnp4d3rv2" |
#        
#        Given terraform map 'task_definition'
#            | varname        | value     |
#            #----------------|-----------|
#            | network_mode   | "awsvpc"  |
#            # Needed because there is no LB
#            | container_name | "example" |
#            | container_port | "80"      |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                      | name         | count |
#            #--------|-------------------------------|--------------|-------|
#            | create | aws_ecs_service               | awsvpc_sd    |       |
#            |        | aws_ecs_task_definition       | default      |       |
#            |        | aws_security_group            | default      |       |
#            |        | aws_security_group_rule       | service_in   |       |
#            |        | aws_security_group_rule       | service_icmp |       |
#            |        | aws_security_group_rule       | service_out  |       |
#            |        | aws_service_discovery_service | default      |       |
#        
#        When we run terraform apply
#        
#        Then aws ECS has services in a steady state
#            |key       | value                   |
#            #----------|-------------------------|
#            | services | ${var.ecs service name} |
#            | cluster  | ${var.cluster}          |
#            | timeout  | 00:30                   |
    
    # COMPLETE
#    @EC2
#    Scenario: Instance of 'aws_ecs_service' 'default'
#        Given terraform tfvars
#            | varname     | value |
#            #-------------|-------|
#            | launch_type | "EC2" |
#        
#        Given terraform map 'task_definition'
#            | varname        | value    |
#            #----------------|----------|
#            | network_mode   | "bridge" |
#            | container_name | "apache" |
#            | container_port | "80"     |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                | name    | count |
#            #--------|-------------------------|---------|-------|
#            | create | aws_ecs_service         | default |       |
#            |        | aws_ecs_task_definition | default |       |
#        
#        When we run terraform apply
#        
#        Then aws ECS has services in a steady state
#            |key       | value                   |
#            #----------|-------------------------|
#            | services | ${var.ecs service name} |
#            | cluster  | ${var.cluster}          |
#            | timeout  | 00:30                   |
    
#    @EC2
#    Scenario: Instance of 'aws_ecs_service' 'lb'
#        Given terraform tfvars
#            | varname     | value |
#            #-------------|-------|
#            | launch_type | "EC2" |
#        
#        Given terraform map 'load_balancer'
#            | varname            | value                                              |
#            #--------------------|----------------------------------------------------|
#            | name               | "public"                                           |
#            | port               | "443"                                              |
#            | container_name     | "apache"                                           |
#            | container_port     | "80"                                               |
#            | host_header        | "${var.ecs service name}.as-test.techservices.illinois.edu" |
#            #NOTE: ssl checks will fail (ignore for now)
#            | certificate_domain | "bridge-example.as-test.techservices.illinois.edu" |
#        
#        Given terraform map 'task_definition'
#            | varname        | value    |
#            #----------------|----------|
#            | network_mode   | "bridge" |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                    | name    | count |
#            #--------|-----------------------------|---------|-------|
#            | create | aws_alb_listener_rule       | default |       |
#            |        | aws_ecs_service             | lb      |       |
#            |        | aws_ecs_task_definition     | default |       |
#            |        | aws_lb_listener_certificate | default |       |
#            |        | aws_lb_target_group         | default |       |
#        
#        When we run terraform apply
#        
#        Then aws ECS has services in a steady state
#            |key       | value                   |
#            #----------|-------------------------|
#            | services | ${var.ecs service name} |
#            | cluster  | ${var.cluster}          |
#            | timeout  | 00:30                   |
        # TODO:
        #   curl host_header (spoof the host header by setting host header to load_balancer.host_header)"
    
#    @EC2
#    Scenario: Instance of 'aws_ecs_service' 'lb' PRIVATE
#              - Proving that service discovery is causing the errors of other scenarios
#                + 'aws_ecs_service' 'all'
#                + etc.
#        Given terraform tfvars
#            | varname     | value |
#            #-------------|-------|
#            | launch_type | "EC2" |
#        
#        Given terraform map 'load_balancer'
#            | varname        | value                                              |
#            #----------------|----------------------------------------------------|
#            | name           | "private"                                          |
#            | port           | "80"                                               |
#            | container_name | "apache"                                           |
#            | container_port | "80"                                               |
#            #| host_header    | "${var.ecs service name}.as-test.techservices.illinois.edu" |
#            | host_header    | "${var.ecs service name}.local" |
#        
#        Given terraform map 'task_definition'
#            | varname        | value    |
#            #----------------|----------|
#            | network_mode   | "bridge" |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                | name    | count |
#            #--------|-------------------------|---------|-------|
#            | create | aws_alb_listener_rule   | default |       |
#            |        | aws_ecs_service         | lb      |       |
#            |        | aws_ecs_task_definition | default |       |
#            |        | aws_lb_target_group     | default |       |
#        
#        When we run terraform apply
#        
#        Then aws ECS has services in a steady state
#            |key       | value                   |
#            #----------|-------------------------|
#            | services | ${var.ecs service name} |
#            | cluster  | ${var.cluster}          |
#            | timeout  | 00:30                   |
#       # TODO:
#       #    curl host_header (spoof: '') IFF in VPC
#    
#    # COMPLETE
#    @EC2
#    Scenario: Instance of 'aws_ecs_service' 'sd'
#        Given terraform tfvars
#            | varname     | value |
#            #-------------|-------|
#            | launch_type | "EC2" |
#        
#        Given terraform map 'service_discovery'
#            | varname        | value                 |
#            #----------------|-----------------------|
#            | namespace_id   | "ns-vf7wvzzwnp4d3rv2" |
#            | type           | "SRV"                 |
#            | container_name | "apache"              |
#            | container_port | "80"                  |
#        
#        Given terraform map 'task_definition'
#            | varname        | value     |
#            #----------------|-----------|
#            | network_mode   | "bridge"  |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                      | name    | count |
#            #--------|-------------------------------|---------|-------|
#            | create | aws_ecs_service               | sd      |       |
#            |        | aws_ecs_task_definition       | default |       |
#            |        | aws_service_discovery_service | default |       |
#        
#        When we run terraform apply
#        
#        Then aws ECS has services in a steady state
#            |key       | value                   |
#            #----------|-------------------------|
#            | services | ${var.ecs service name} |
#            | cluster  | ${var.cluster}          |
#            | timeout  | 00:30                   |
    
#    @EC2
#    Scenario: Instance of 'aws_service_discovery_service' 'health_check'
#              Health check config can only be applied to a public namespace.
#        Given terraform tfvars
#            | varname     | value |
#            #-------------|-------|
#            | launch_type | "EC2" |
#        
#        Given terraform map 'load_balancer'
#            | varname        | value                                              |
#            #----------------|----------------------------------------------------|
#            | name           | "public"                                           |
#            | port           | "443"                                              |
#            | container_name | "apache"                                           |
#            | container_port | "80"                                               |
#            | host_header    | "${var.ecs service name}.as-test.techservices.illinois.edu" |
#       
#        Given terraform map 'service_discovery'
#            | varname      | value                 |
#            #--------------|-----------------------|
#            | namespace_id | "ns-pomsm4cehdoviesw" |
#            | type         | "SRV"                 |
#        
#        Given terraform map 'service_discovery_health_check_config'
#            | varname           | value  |
#            #-------------------|--------|
#            | failure_threshold | 1      |
#            | type              | "HTTP" |
#        
#        Given terraform map 'task_definition'
#            | varname        | value     |
#            #----------------|-----------|
#            | network_mode   | "bridge"  |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                      | name         | count |
#            #--------|-------------------------------|--------------|-------|
#            | create | aws_alb_listener_rule         | default      |       |
#            |        | aws_ecs_service               | all          |       |
#            |        | aws_ecs_task_definition       | default      |       |
#            |        | aws_lb_target_group           | default      |       |
#            |        | aws_service_discovery_service | health_check |       |
#        
#        When we run terraform apply
#        
#        Then aws ECS has services in a steady state
#            |key       | value                   |
#            #----------|-------------------------|
#            | services | ${var.ecs service name} |
#            | cluster  | ${var.cluster}          |
#            | timeout  | 00:30                   |
        # TODO:
        #   curl host_header (spoof: '')
    
#    @EC2
#    Scenario: Instance of 'aws_service_discovery_service' 'health_check_and_health_check_custom'
#              - This configuration is not currently supported by AWS, cannot apply
#              Health check config can only be applied to a public namespace.
#        
#        Given terraform tfvars
#            | varname     | value |
#            #-------------|-------|
#            | launch_type | "EC2" |
#        
#        Given terraform map 'load_balancer'
#            | varname        | value                                              |
#            #----------------|----------------------------------------------------|
#            | name           | "public"                                           |
#            | port           | "443"                                              |
#            | container_name | "apache"                                           |
#            | container_port | "80"                                               |
#            | host_header    | "${var.ecs service name}.as-test.techservices.illinois.edu" |
#       
#        Given terraform map 'service_discovery'
#            | varname      | value                 |
#            #--------------|-----------------------|
#            | namespace_id | "ns-pomsm4cehdoviesw" |
#            | type         | "SRV"                 |
#        
#        Given terraform map 'service_discovery_health_check_config'
#            | varname           | value  |
#            #-------------------|--------|
#            | failure_threshold | 1      |
#            | type              | "HTTP" |
#        
#        Given terraform map 'service_discovery_health_check_custom_config'
#            | varname           | value  |
#            #-------------------|--------|
#            | failure_threshold | 1      |
#        
#        Given terraform map 'task_definition'
#            | varname        | value    |
#            #----------------|----------|
#            | network_mode   | "bridge" |
#        
#        When we run terraform plan
#        
#        Then terraform plans to perform these exact resource actions
#            | action | resource                      | name                                 | count |
#            #--------|-------------------------------|--------------------------------------|-------|
#            | create | aws_alb_listener_rule         | default                              |       |
#            |        | aws_ecs_service               | all                                  |       |
#            |        | aws_ecs_task_definition       | default                              |       |
#            |        | aws_lb_target_group           | default                              |       |
#            |        | aws_service_discovery_service | health_check_and_health_check_custom |       |
#        
#        # Apply fails. Amazon support issue.
#        Given we expect this scenario to fail
#        When we run terraform apply
