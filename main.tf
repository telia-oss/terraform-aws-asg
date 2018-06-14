# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
resource "aws_iam_role" "main" {
  name               = "${var.prefix}-role"
  assume_role_policy = "${data.aws_iam_policy_document.main.json}"
}

data "aws_iam_policy_document" "main" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.prefix}-profile"
  role = "${aws_iam_role.main.name}"
}

resource "aws_iam_role_policy" "main" {
  name   = "${var.prefix}-permissions"
  role   = "${aws_iam_role.main.id}"
  policy = "${var.instance_policy}"
}

resource "aws_security_group" "main" {
  name        = "${var.prefix}-sg"
  description = "Terraformed security group."
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(var.tags, map("Name", "${var.prefix}-sg"))}"
}

resource "aws_security_group_rule" "egress" {
  security_group_id = "${aws_security_group.main.id}"
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "main" {
  name_prefix          = "${var.prefix}-asg-"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
  security_groups      = ["${aws_security_group.main.id}"]
  image_id             = "${var.instance_ami}"
  key_name             = "${var.instance_key}"
  user_data            = "${var.user_data}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.instance_volume_size}"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  asg_tags = "${merge(var.tags, map("Name", "${var.prefix}"))}"
}

data "null_data_source" "autoscaling" {
  count = "${length(local.asg_tags)}"

  inputs = {
    Key               = "${element(keys(local.asg_tags), count.index)}"
    Value             = "${element(values(local.asg_tags), count.index)}"
    PropagateAtLaunch = "TRUE"
  }
}

resource "aws_cloudformation_stack" "main" {
  depends_on    = ["aws_launch_configuration.main"]
  name          = "${var.prefix}-asg"
  template_body = "${data.template_file.main.rendered}"
}

data "template_file" "main" {
  template = "${file("${path.module}/cloudformation.yml")}"

  vars {
    prefix               = "${var.prefix}"
    launch_configuration = "${aws_launch_configuration.main.name}"
    health_check_type    = "${var.health_check_type}"
    await_signal         = "${var.await_signal}"
    pause_time           = "${var.pause_time}"
    min_size             = "${var.instance_count}"
    max_size             = "${var.instance_count_max}"
    subnets              = "${jsonencode(var.subnet_ids)}"
    tags                 = "${jsonencode(data.null_data_source.autoscaling.*.outputs)}"
  }
}
