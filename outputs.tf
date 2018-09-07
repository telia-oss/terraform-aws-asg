# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  description = "The autoscaling group id (name)."
  value       = "${aws_cloudformation_stack.main.outputs["AsgName"]}"
}

output "role_id" {
  description = "The id of the instance role."
  value       = "${aws_iam_role.main.id}"
}

output "role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the instance role."
  value       = "${aws_iam_role.main.arn}"
}

output "security_group_id" {
  description = "The id of the security group."
  value       = "${aws_security_group.main.id}"
}
