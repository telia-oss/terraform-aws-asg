# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  description = "The autoscaling group id (name)."
  value       = aws_autoscaling_group.main.name
}

output "role_name" {
  description = "The name of the instance role."
  value       = aws_iam_role.main.name
}

output "role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the instance role."
  value       = aws_iam_role.main.arn
}

output "security_group_id" {
  description = "The ID of the security group."
  value       = aws_security_group.main.id
}

