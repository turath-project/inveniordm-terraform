#------------------------------------------------------------------------------#
# Variables for the infrastructure
#------------------------------------------------------------------------------#

//********************************* AWS *********************************//
variable "aws_region" {
  default     = "eu-north-1"
  description = "Default aws region"
}

variable "project_name" {
  default     = "invenio"
  description = "Name of the project"
}

#variable "dns_zone" {
#  type        = string
#}

variable "certificate_domain" {
  default     = "test2-invenio.devlits.com"
  type = string
  description = "The domain of the static site, eg example.com"
}

variable "certificate_sans" {
  default     = ["test2-invenio.devlits.com"]
  type = list(string)
#  type = string
  description = "List of subject alternative names"
}

//***************************** PostgreSQL *****************************//
variable "postgres_instance" {
  default     = "db.t3.micro"
  description = "Instance type for PostgreSQL"
}
//***************************** ECS cluster *****************************//

# The available CPU and Memory values are listed here => (https://docs.aws.amazon.com/en_us/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)##
variable "app_container_name" {
  default     = "app"
  description = "Default container name"
}

variable "app_container_port" {
  default     = "5000"
  description = "Default app port"
}

variable "fargate_cpu" {
  default     = "512"
  description = "The number of CPU units used by the task. You must use one of the supported values. For example: 512 (.5 vCPU)"
}

variable "fargate_memory" {
  default     = "1024"
  description = "The number of memory units used by the task. You must use one of the supported values. For example: 1024 (1GB)"
}

variable "ecs_service_count" {
  default     = "1"
  description = "The number of instances of the task definition to place and keep running"
}

#variable "ecr_repo" {
#  default     = ""
#  description = "ECR repo for the project"
#}
//***************************** AutoScaling *****************************//

variable "ecs_autoscale_max" {
  default     = "3"
  description = "The minimum number of containers that should be running."
}

variable "ecs_autoscale_min" {
  default     = "1"
  description = "The maximum number of containers that should be running."
}

variable "ecs_as_cpu_low_threshold_per" {
  default     = "20"
  description = "If the average CPU utilization over a minute drops to this threshold, the number of containers will be reduced (but not below ecs_autoscale_min_instances)"
}

variable "ecs_as_cpu_high_threshold_per" {
  default     = "80"
  description = "If the average CPU utilization over a minute rises to this threshold, the number of containers will be increased (but not above ecs_autoscale_max_instances)"
}

//***************************** Gitlab runner *****************************//

#variable "gitlab_runner" {
#  default     = ""
#  description = "default name for gitlab runner"
#}
#
#variable "runner_token" {
#  default     = ""
#  description = "gitlab runner token"
#}
#
#variable "environment" {
#  default     = ""
#  description = "default env"
#}
#
#variable "gitlab_url" {
#  default     = "https://gitlab.com"
#  description = "default url for gitlab runner"
#}
#
#variable "runner_instance_type" {
#  default     = ""
#  description = "instance type for gitlab runner"
#}
#
#variable "timezone" {
#  default     = "Europe/London"
#  description = "default timezone for gitlab runner autoscaling"
#}
