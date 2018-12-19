provider "aws" {
  region = "eu-west-1"
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
  source       = "../../"
  name_prefix  = "default-test"
  vpc_id       = "${data.aws_vpc.main.id}"
  subnet_ids   = ["${data.aws_subnet_ids.main.ids}"]
  instance_ami = "${data.aws_ami.linux2.id}"
}

output "id" {
  value = "${module.asg.id}"
}
