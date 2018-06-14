# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  value = "${aws_cloudformation_stack.main.outputs["AsgName"]}"
}

output "role_name" {
  value = "${aws_iam_role.main.name}"
}

output "role_arn" {
  value = "${aws_iam_role.main.arn}"
}

output "role_id" {
  value = "${aws_iam_role.main.id}"
}

output "security_group_id" {
  value = "${aws_security_group.main.id}"
}
