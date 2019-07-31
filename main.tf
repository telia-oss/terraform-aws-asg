# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
resource "aws_iam_role" "main" {
  name               = "${var.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.main.json
  tags               = merge(var.tags, { "Name" = "${var.name_prefix}-role" })
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
  policy = coalesce(var.instance_policy, data.aws_iam_policy_document.placeholder.json)
}

data "aws_iam_policy_document" "placeholder" {
  statement {
    sid           = "placeholder"
    effect        = "Deny"
    not_actions   = ["*"]
    not_resources = ["*"]
  }
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
    iterator = device
    for_each = var.ebs_block_devices

    content {
      device_name           = lookup(device.value, "device_name", null)
      delete_on_termination = lookup(device.value, "delete_on_termination", null)
      encrypted             = lookup(device.value, "encrypted", null)
      iops                  = lookup(device.value, "iops", null)
      no_device             = lookup(device.value, "no_device", null)
      snapshot_id           = lookup(device.value, "snapshot_id", null)
      volume_size           = lookup(device.value, "volume_size", null)
      volume_type           = lookup(device.value, "volume_type", null)
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
  asg_tags = [
    for k, v in merge(var.tags, { "Name" = "${var.name_prefix}" }) : {
      Key               = k
      Value             = v
      PropagateAtLaunch = "TRUE"
    }
  ]
}

resource "aws_cloudformation_stack" "main" {
  depends_on    = [aws_launch_configuration.main]
  name          = "${var.name_prefix}-asg"
  template_body = <<EOF
Description: "Autoscaling group created by Terraform."
Resources:
  AutoScalingGroup:
    Type: "AWS::AutoScaling::AutoScalingGroup"
    Properties:
      Cooldown: 300
      HealthCheckType: "${var.health_check_type}"
      HealthCheckGracePeriod: 300
      LaunchConfigurationName: "${aws_launch_configuration.main.id}"
      MinSize: "${var.min_size}"
      MaxSize: "${var.max_size}"
      MetricsCollection:
        - Granularity: 1Minute
          Metrics:
            - GroupMinSize
            - GroupMaxSize
            - GroupDesiredCapacity
            - GroupInServiceInstances
            - GroupPendingInstances
            - GroupStandbyInstances
            - GroupTerminatingInstances
            - GroupTotalInstances
      Tags: ${jsonencode(local.asg_tags)}
      TerminationPolicies:
        - OldestLaunchConfiguration
        - OldestInstance
        - Default
      VPCZoneIdentifier: ${jsonencode(var.subnet_ids)}
    UpdatePolicy:
      AutoScalingRollingUpdate:
        MinInstancesInService: "${var.min_size}"
        MaxBatchSize: "2"
        WaitOnResourceSignals: "${var.await_signal}"
        PauseTime: "${var.pause_time}"
        SuspendProcesses:
          - HealthCheck
          - ReplaceUnhealthy
          - AZRebalance
          - AlarmNotification
          - ScheduledActions
Outputs:
  AsgName:
    Description: The name of the auto scaling group
    Value: !Ref AutoScalingGroup
EOF
}
