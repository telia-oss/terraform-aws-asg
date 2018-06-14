provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}

module "asg" {
  source          = "../../"
  prefix          = "your-project"
  user_data       = "#!bin/bash\necho hello world"
  vpc_id          = "${data.aws_vpc.main.id}"
  subnet_ids      = ["${data.aws_subnet_ids.main.ids}"]
  instance_policy = "${data.aws_iam_policy_document.permissions.json}"

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

resource "aws_security_group_rule" "ingress" {
  security_group_id = "${module.asg.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_iam_policy_document" "permissions" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:AssociateAddress",
    ]

    resources = ["*"]
  }
}

output "security_group_id" {
  value = "${module.asg.security_group_id}"
}

output "role_arn" {
  value = "${module.asg.role_arn}"
}
