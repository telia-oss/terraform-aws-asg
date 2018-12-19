#!/bin/sh
set -eo pipefail

# for integer comparisons: check_counts <testValue> <expectedValue> <testName>
check_counts() {
 if [ $1 -eq $2 ]
 then
   echo "√ $3"
 else
   echo "✗ $3"
   tests_failed=$((tests_failed+1))
fi
}

tests_failed=0

if [ ! -z $1 ] && [ $1 == "ci" ]
  then
  ASG_ID=`cat terraform-out/terraform-out.json |jq -r '.id.value'`
  export AWS_DEFAULT_REGION=eu-west-1
  else
  ASG_ID=`terraform output -json  |jq -r '.id.value'`
fi

instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_ID | jq -r '.AutoScalingGroups[].Instances[].InstanceId'`
instance_count=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_ID | jq '.AutoScalingGroups[].Instances' | jq -s length`
public_ip=`aws ec2 describe-instances --filter "Name=instance-id,Values=${instance_id}"|jq -r .Reservations[].Instances[].NetworkInterfaces[].Association.PublicIp`

if ( $(nc -zv ${public_ip} 22 2>&1 | grep -q succeeded) )
  then
  echo "√ Port 22 Open on Instance"
  else
  echo "✗ Port 22 Open on Instance"
  tests_failed=$((tests_failed+1))
fi

check_counts $instance_count 1 "Expected # of Instances"

exit $tests_failed