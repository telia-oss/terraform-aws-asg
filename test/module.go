package module

import (
	"encoding/base64"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/stretchr/testify/assert"
)

// Expectations for the autoscaling test suite.
type Expectations struct {
	MinSize         int64
	MaxSize         int64
	DesiredCapacity int64
	UserData        []string
	InstanceType    string
	Volumes         []string
	InstanceTags    map[string]string
}

// RunTestSuite runs the test suite against the autoscaling group.
func RunTestSuite(t *testing.T, name, region string, expected Expectations) {
	var (
		group     *autoscaling.Group
		config    *autoscaling.LaunchConfiguration
		instances []*ec2.Instance
	)
	sess := NewSession(t, region)

	group = DescribeAutoScalingGroup(t, sess, name)
	assert.Equal(t, expected.MinSize, aws.Int64Value(group.MinSize))
	assert.Equal(t, expected.MaxSize, aws.Int64Value(group.MaxSize))
	assert.Equal(t, expected.DesiredCapacity, aws.Int64Value(group.DesiredCapacity))

	config = DescribeLaunchConfiguration(t, sess, aws.StringValue(group.LaunchConfigurationName))

	userData := DecodeUserData(t, config.UserData)
	for _, data := range expected.UserData {
		assert.Contains(t, userData, data)
	}

	// Wait for capacity in the autoscaling group (max 10min wait)
	WaitForCapacity(t, sess, name, 10*time.Second, 10*time.Minute)
	instances = DescribeInstances(t, sess, name)

	for _, instance := range instances {
		assert.Equal(t, expected.InstanceType, aws.StringValue(instance.InstanceType))

		devices := GetInstanceBlockDeviceMappings(instance)
		for _, v := range expected.Volumes {
			if _, ok := devices[v]; !ok {
				t.Errorf("missing block device on instance: %s", v)
			}
		}

		tags := GetInstanceTags(instance)
		for k, want := range expected.InstanceTags {
			got, ok := tags[k]
			if assert.True(t, ok) {
				assert.Equal(t, want, got)
			}
		}
	}

}

func NewSession(t *testing.T, region string) *session.Session {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		t.Fatalf("failed to create new AWS session: %s", err)
	}
	return sess
}

func DecodeUserData(t *testing.T, data *string) string {
	b, err := base64.StdEncoding.DecodeString(aws.StringValue(data))
	if err != nil {
		t.Fatalf("failed to decode user data: %s", err)
	}
	return string(b)
}

func GetInstanceBlockDeviceMappings(instance *ec2.Instance) map[string]*ec2.InstanceBlockDeviceMapping {
	devices := make(map[string]*ec2.InstanceBlockDeviceMapping)
	for _, d := range instance.BlockDeviceMappings {
		devices[aws.StringValue(d.DeviceName)] = d
	}
	return devices
}

func GetInstanceTags(instance *ec2.Instance) map[string]string {
	tags := make(map[string]string)
	for _, t := range instance.Tags {
		tags[aws.StringValue(t.Key)] = aws.StringValue(t.Value)
	}
	return tags
}

func DescribeAutoScalingGroup(t *testing.T, sess *session.Session, asgName string) *autoscaling.Group {
	c := autoscaling.New(sess)

	out, err := c.DescribeAutoScalingGroups(&autoscaling.DescribeAutoScalingGroupsInput{
		AutoScalingGroupNames: []*string{aws.String(asgName)},
	})
	if err != nil {
		t.Fatalf("failed to describe autoscaling groups: %s", err)
	}
	if n := len(out.AutoScalingGroups); n != 1 {
		t.Fatalf("found wrong number (%d) of matches for group: %s", n, asgName)
	}

	var group *autoscaling.Group
	for _, g := range out.AutoScalingGroups {
		if name := aws.StringValue(g.AutoScalingGroupName); name != asgName {
			t.Fatalf("wrong autoscaling group name: %s", name)
		}
		group = g
	}
	return group
}

func DescribeLaunchConfiguration(t *testing.T, sess *session.Session, configName string) *autoscaling.LaunchConfiguration {
	c := autoscaling.New(sess)

	out, err := c.DescribeLaunchConfigurations(&autoscaling.DescribeLaunchConfigurationsInput{
		LaunchConfigurationNames: []*string{aws.String(configName)},
	})
	if err != nil {
		t.Fatalf("failed to describe launch config: %s", err)
	}
	if n := len(out.LaunchConfigurations); n != 1 {
		t.Fatalf("found wrong number (%d) of matches for config: %s", n, configName)
	}

	var config *autoscaling.LaunchConfiguration
	for _, c := range out.LaunchConfigurations {
		if name := aws.StringValue(c.LaunchConfigurationName); name != configName {
			t.Fatalf("wrong autoscaling group name: %s", name)
		}
		config = c
	}
	return config
}

func DescribeInstances(t *testing.T, sess *session.Session, asgName string) []*ec2.Instance {
	group := DescribeAutoScalingGroup(t, sess, asgName)

	var ids []*string
	for _, instance := range group.Instances {
		ids = append(ids, instance.InstanceId)
	}
	if len(ids) < 1 {
		t.Fatal("no instances in autoscaling group")
	}

	c := ec2.New(sess)
	out, err := c.DescribeInstances(&ec2.DescribeInstancesInput{
		InstanceIds: ids,
	})
	if err != nil {
		t.Fatalf("failed to describe instances: %s", err)
	}

	var instances []*ec2.Instance
	for _, reservation := range out.Reservations {
		for _, instance := range reservation.Instances {
			instances = append(instances, instance)
		}
	}
	return instances
}

func WaitForCapacity(t *testing.T, sess *session.Session, asgName string, checkInterval time.Duration, timeoutLimit time.Duration) {
	interval := time.NewTicker(checkInterval)
	defer interval.Stop()

	timeout := time.NewTimer(timeoutLimit)
	defer timeout.Stop()

WaitLoop:
	for {
		select {
		case <-interval.C:
			t.Log("waiting for capacity...")
			group := DescribeAutoScalingGroup(t, sess, asgName)
			if aws.Int64Value(group.DesiredCapacity) == int64(len(group.Instances)) {
				break WaitLoop
			}
		case <-timeout.C:
			t.Fatal("timeout reached while waiting for autoscaling group capacity")
		}
	}
}
