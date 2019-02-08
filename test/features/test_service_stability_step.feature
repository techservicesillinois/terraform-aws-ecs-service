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
              "healthcheck": {
                  "command": [
                    "CMD-SHELL",
                    "exit 0"
                  ],
                  "interval": 30,
                  "retries": 3,
                  "timeout": 5
              },
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
    
    #@wip
    Scenario: Instance of 'aws_ecs_service' 'awsvpc_all'
        
        Given terraform map 'load_balancer'
            | varname        | value                                              |
            #----------------|----------------------------------------------------|
            | name           | "public"                                           |
            | port           | "443"                                              |
            | container_name | "apache"                                           |
            | container_port | "80"                                               |
            | host_header    | "apache-example.as-test.techservices.illinois.edu" |
        
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
            | container_name | "example" |
            | container_port | "80"      |
        
        When we run terraform plan
        
        When we run terraform apply
        
        Then aws ECS has services in a steady state
            |key                    | value                   |
            #-----------------------|-------------------------|
            | services              | ${var.ecs service name} |
            | cluster               | ${var.cluster}          |
            | health check required | False                   |
        
        
    @wip
    Scenario: 'aws_ecs_service' 'awsvpc_all' failure -> non-existent image
        Given we expect this scenario to fail
        Given terraform file 'containers.json'
            """
            [{
              "name": "this-dakr-imuj-duz-not-eksist",
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
        
        Given terraform map 'load_balancer'
            | varname        | value                                              |
            #----------------|----------------------------------------------------|
            | name           | "public"                                           |
            | port           | "443"                                              |
            | container_name | "this-dakr-imuj-duz-not-eksist"                    |
            | container_port | "80"                                               |
            | host_header    | "apache-example.as-test.techservices.illinois.edu" |
        
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
            | container_name | "example" |
            | container_port | "80"      |
        
        When we run terraform plan
        
        When we run terraform apply
        
        Then aws ECS has services in a steady state
            |key                | value                   |
            #-------------------|-------------------------|
            | services          | ${var.ecs service name} |
            | cluster           | ${var.cluster}          |
            | max stopped tasks | 1                       |
        
        
    @wip
    Scenario: 'aws_ecs_service' 'awsvpc_all' failure -> bad health check
        Given we expect this scenario to fail
        Given terraform file 'containers.json'
            """
            [{
              "name": "apache",
              "image": "httpd",
              "healthcheck": {
                  "command": [
                    "CMD-SHELL",
                    "exit 1"
                  ],
                  "interval": 30,
                  "retries": 3,
                  "timeout": 5
              },
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
        
        Given terraform map 'load_balancer'
            | varname        | value                                              |
            #----------------|----------------------------------------------------|
            | name           | "public"                                           |
            | port           | "443"                                              |
            | container_name | "apache"                                           |
            | container_port | "80"                                               |
            | host_header    | "apache-example.as-test.techservices.illinois.edu" |
        
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
            | container_name | "example" |
            | container_port | "80"      |
        
        When we run terraform plan
        
        When we run terraform apply
        
        Then aws ECS has services in a steady state
            |key                | value                   |
            #-------------------|-------------------------|
            | services          | ${var.ecs service name} |
            | cluster           | ${var.cluster}          |
            | max stopped tasks | 1                       |
        
        
    @wip
    Scenario: 'aws_ecs_service' 'awsvpc_all' failure -> bad container (entrypoint)
        Given we expect this scenario to fail
        Given terraform file 'containers.json'
            """
            [{
              "name": "apache",
              "image": "httpd",
              "entryPoint": ["exit 1"],
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
        
        Given terraform map 'load_balancer'
            | varname        | value                                              |
            #----------------|----------------------------------------------------|
            | name           | "public"                                           |
            | port           | "443"                                              |
            | container_name | "apache"                                           |
            | container_port | "80"                                               |
            | host_header    | "apache-example.as-test.techservices.illinois.edu" |
        
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
            | container_name | "example" |
            | container_port | "80"      |
        
        When we run terraform plan
        
        When we run terraform apply
        
        Then aws ECS has services in a steady state
            |key                | value                   |
            #-------------------|-------------------------|
            | services          | ${var.ecs service name} |
            | cluster           | ${var.cluster}          |
            | max stopped tasks | 1                       |
    
    
    
    
    
    
    
    
    
    
    
    
    
    