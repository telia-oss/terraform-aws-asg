terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.17"
  region  = "${var.region}"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
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
  name_prefix          = var.name_prefix
  vpc_id               = data.aws_vpc.main.id
  subnet_ids           = data.aws_subnet_ids.main.ids
  instance_ami         = data.aws_ami.linux2.id
  instance_policy      = data.aws_iam_policy_document.permissions.json
  instance_volume_size = 10
  min_size             = 2
  max_size             = 4
  user_data_base64     = data.template_cloudinit_config.user_data.rendered

  ebs_block_devices = [
    {
      device_name           = "/dev/xvdcz"
      volume_type           = "gp2"
      volume_size           = 22
      delete_on_termination = true
    },
  ]

  tags = {
    terraform   = "True"
    environment = "dev"
  }
}

data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
runcmd:
  - echo "Cloud init part 1"
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = "echo \"Cloud init part 2\""
  }
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
