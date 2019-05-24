# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
resource "aws_iam_role" "main" {
  name               = "${var.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.main.json
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
  name = "${var.name_prefix}-profile"
  role = aws_iam_role.main.name
}

resource "aws_iam_role_policy" "main" {
  name   = "${var.name_prefix}-permissions"
  role   = aws_iam_role.main.id
  policy = var.instance_policy
}

resource "aws_security_group" "main" {
  name        = "${var.name_prefix}-sg"
  description = "Terraformed security group."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-sg"
    },
  )
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_launch_configuration" "main" {
  name_prefix          = "${var.name_prefix}-asg-"
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.main.name
  security_groups      = [aws_security_group.main.id]
  image_id             = var.instance_ami
  key_name             = var.instance_key
  user_data            = var.user_data
  dynamic "ebs_block_device" {
    for_each = [var.ebs_block_devices]
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      no_device             = lookup(ebs_block_device.value, "no_device", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.instance_volume_size
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  asg_tags = merge(
    var.tags,
    {
      "Name" = var.name_prefix
    },
  )
}

data "null_data_source" "autoscaling" {
  count = length(local.asg_tags)

  inputs = {
    Key               = element(keys(local.asg_tags), count.index)
    Value             = element(values(local.asg_tags), count.index)
    PropagateAtLaunch = "TRUE"
  }
}

resource "aws_cloudformation_stack" "main" {
  depends_on    = [aws_launch_configuration.main]
  name          = "${var.name_prefix}-asg"
  template_body = data.template_file.main.rendered
}

data "template_file" "main" {
  template = file("${path.module}/cloudformation.yml")

  vars = {
    launch_configuration = aws_launch_configuration.main.name
    health_check_type    = var.health_check_type
    await_signal         = var.await_signal
    pause_time           = var.pause_time
    min_size             = var.min_size
    max_size             = var.max_size
    subnets              = jsonencode(var.subnet_ids)
    tags                 = jsonencode(data.null_data_source.autoscaling.*.outputs)
  }
}

