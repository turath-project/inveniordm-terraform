#---------------------------------------------#
# IAM roles, instance profiles & policies
#---------------------------------------------#
resource "aws_iam_role" "instance_role" {
  name = "${var.project_name}-instance-role"
  path = "/"
  assume_role_policy = <<ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  ROLE
}

resource "aws_iam_role" "ecs_role" {
  name = "${var.project_name}-ecs-role"
  path = "/"
  assume_role_policy = <<ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  ROLE
}

resource "aws_iam_role" "ecs_tasks_role" {
  name = "${var.project_name}-ecs-tasks-role"
  path = "/"
  assume_role_policy = <<ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  ROLE
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "${var.project_name}-service-profile"
  role = "${aws_iam_role.ecs_role.name}"
}

resource "aws_iam_instance_profile" "ecs_tasks_profile" {
  name = "${var.project_name}-ecs-tasks-profile"
  role = "${aws_iam_role.ecs_tasks_role.name}"
}

resource "aws_iam_role_policy_attachment" "instance_policy_attachment" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  role = "${aws_iam_role.ecs_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_policy_attachment" {
  role = "${aws_iam_role.ecs_tasks_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
