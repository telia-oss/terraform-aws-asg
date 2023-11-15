# ------------------------------------------------------------------------------
# Data
# ------------------------------------------------------------------------------

data "aws_subnet" "selected" {
  id = var.subnet_ids[0]
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "ID of subnets where instances can be provisioned."
  type        = list(string)
}

variable "user_data" {
  description = "The user data to provide when launching the instance."
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Use this instead of user_data whenever the value is not a valid UTF-8 string."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Type of instance to provision."
  type        = string
  default     = "t3.micro"
}

variable "instance_ami" {
  description = "The EC2 image ID to launch."
  type        = string
}

variable "instance_policy" {
  description = "A policy document to apply to the instance profile."
  type        = string
  default     = ""
}

variable "instance_key" {
  description = "The key name that should be used for the instance."
  type        = string
  default     = ""
}

variable "instance_volume_size" {
  description = "The size of the volume in gigabytes."
  type        = number
  default     = 30
}

variable "encrypt_root_volume" {
  description = "Encrypt root volume."
  type        = bool
  default     = false
}

variable "root_volume_iops" {
  description = "The amount of provisioned IOPS. This must be set with a volume_type of 'io1`."
  type        = number
  default     = null
}

variable "root_volume_type" {
  description = "The type of volume. Can be `standard`, `gp2`, or `io1`. "
  type        = string
  default     = "gp2"
}

variable "ebs_block_devices" {
  description = "Additional EBS block devices to attach to the instance."
  type        = list(map(string))
  default     = []
}

variable "min_size" {
  description = "The minimum (and desired) size of the auto scale group."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum size of the auto scale group."
  type        = number
  default     = 3
}

variable "target_group_arns" {
  description = "A list of Amazon Resource Names (ARN) of target groups to associate with the Auto Scaling group."
  type        = list
  default     = []
}

variable "health_check_type" {
  description = "EC2 or ELB. Controls how health checking is done."
  type        = string
  default     = "EC2"
}

variable "await_signal" {
  description = "Await signals (WaitOnResourceSignals) for the autoscaling rolling update policy."
  type        = bool
  default     = false
}

variable "pause_time" {
  description = "Pause time for the autoscaling rolling update policy."
  type        = string
  default     = "PT5M"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "associate_public_ip_address" {
  description = "Associate a public ip address with an instance in a VPC"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring. This is enabled by default."
  type        = bool
  default     = true
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
}

variable "spot_price" {
  description = "The price to use for reserving spot instances"
  type        = string
  default     = ""
}

variable "placement_tenancy" {
  description = "The tenancy of the instance. Valid values are 'default' or 'dedicated'"
  type        = string
  default     = "default"
}
