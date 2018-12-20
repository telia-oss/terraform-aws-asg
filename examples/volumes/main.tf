terraform {
  required_version = "0.11.10"

  backend "s3" {
    key            = "terraform-modules/development/terraform-aws-asg/volumes.tfstate"
    bucket         = "<test-account-id>-terraform-state"
    dynamodb_table = "<test-account-id>-terraform-state"
    acl            = "bucket-owner-full-control"
    encrypt        = "true"
    kms_key_id     = "<kms-key-id>"
    region         = "eu-west-1"
  }
}

provider "aws" {
  version             = "1.52.0"
  region              = "eu-west-1"
  allowed_account_ids = ["<test-account-id>"]
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}

data "aws_ami" "linux2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami*gp2"]
  }
}

module "asg" {
  source               = "../../"
  name_prefix          = "asg-volumes-test"
  vpc_id               = "${data.aws_vpc.main.id}"
  subnet_ids           = ["${data.aws_subnet_ids.main.ids}"]
  instance_ami         = "${data.aws_ami.linux2.id}"
  instance_policy      = "${data.aws_iam_policy_document.permissions.json}"
  instance_volume_size = "10"
  user_data            = "#!/bin/bash\necho hello world"

  ebs_block_devices = [{
    device_name           = "/dev/xvdcz"
    volume_type           = "gp2"
    volume_size           = "22"
    delete_on_termination = true
  }]

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

output "id" {
  value = "${module.asg.id}"
}
