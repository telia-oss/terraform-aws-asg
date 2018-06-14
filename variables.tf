# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "prefix" {
  description = "A prefix used for naming resources."
}

variable "user_data" {
  description = "User data script for the launch configuration."
  default     = ""
}

variable "health_check_type" {
  description = "Optional: Type of health check to use - either ELB or EC2."
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

variable "vpc_id" {
  description = "ID of the VPC for the subnets."
}

variable "subnet_ids" {
  description = "ID of subnets where instances can be provisioned."
  type        = "list"
}

variable "instance_type" {
  description = "Type of instance to provision."
  default     = "t2.micro"
}

variable "instance_volume_size" {
  description = "Size of the root block device."
  default     = "8"
}

variable "instance_count" {
  description = "Desired (and minimum) number of instances."
  default     = "1"
}

variable "instance_count_max" {
  description = "Maximum number of instances."
  default     = "3"
}

variable "instance_ami" {
  description = "AMI id for the launch configuration."
  default     = "ami-db51c2a2"
}

variable "instance_key" {
  description = "Name of an EC2 key-pair for SSH access."
  default     = ""
}

// Workaround because we cannot use count since the instance policy can be computed in some cases.
variable "instance_policy" {
  description = "Optional: A policy document which is applied to the instance profile."

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

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}
