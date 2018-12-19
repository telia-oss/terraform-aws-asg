# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "subnet_ids" {
  description = "ID of subnets where instances can be provisioned."
  type        = "list"
}

// Work around as default cannot be ""
variable "user_data" {
  description = "The user data to provide when launching the instance."
  default     = "#!bin/bash\necho \"user_data script complete\""
}

variable "instance_type" {
  description = "Type of instance to provision."
  default     = "t3.micro"
}

variable "instance_ami" {
  description = "The EC2 image ID to launch."
}

variable "instance_key" {
  description = "The key name that should be used for the instance."
  default     = ""
}

variable "instance_volume_size" {
  description = "The size of the volume in gigabytes."
  default     = "30"
}

variable "ebs_block_devices" {
  description = "Additional EBS block devices to attach to the instance."
  type        = "list"
  default     = []
}

// Workaround because we cannot use count since the passed policy can be computed in some cases.
variable "instance_policy" {
  description = "A policy document to apply to the instance profile."

  default = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "denynothing",
            "Effect": "Deny",
            "NotAction": "*",
            "NotResource": "*"
        }
    ]
}
EOF
}

variable "min_size" {
  description = "The minimum (and desired) size of the auto scale group."
  default     = "1"
}

variable "max_size" {
  description = "The maximum size of the auto scale group."
  default     = "3"
}

variable "health_check_type" {
  description = "EC2 or ELB. Controls how health checking is done."
  default     = "EC2"
}

variable "await_signal" {
  description = "Await signals (WaitOnResourceSignals) for the autoscaling rolling update policy."
  default     = "false"
}

variable "pause_time" {
  description = "Pause time for the autoscaling rolling update policy."
  default     = "PT5M"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}
