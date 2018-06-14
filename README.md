## Autoscaling group

Easy way of setting up an autoscaling group which supports rolling updates, which also takes care of creating:

- [Launch configuration](https://www.terraform.io/docs/providers/aws/r/launch_configuration.html)
- [Security group](https://www.terraform.io/docs/providers/aws/r/security_group.html) with egress all.
- [IAM instance profile](https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html).

Note that this resource will create a cloudformation stack for the autoscaling group in order to support rolling updates.
