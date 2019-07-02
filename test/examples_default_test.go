package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestDefaultExample(t *testing.T) {
	t.Parallel()

	var (
		namePrefix = fmt.Sprintf("asg-default-test-%s", random.UniqueId())
		// awsRegion  = aws.GetRandomStableRegion(t, nil, nil)
		awsRegion  = "eu-west-1"
		exampleDir = "../examples/default"
	)

	terraformOptions := &terraform.Options{
		TerraformDir: exampleDir,

		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	// Deploy
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	asgName := terraform.Output(t, terraformOptions, "id")

	// Tests for the ASG
	capacity := aws.GetCapacityInfoForAsg(t, asgName, awsRegion)
	assert.EqualValues(t, 1, capacity.MinCapacity)
	assert.EqualValues(t, 1, capacity.DesiredCapacity)
	assert.EqualValues(t, 3, capacity.MaxCapacity)

	aws.WaitForCapacity(t, asgName, awsRegion, 10, 30*time.Second)

	// Tests for instances in the ASG
	instanceIDs := aws.GetInstanceIdsForAsg(t, asgName, awsRegion)
	for _, id := range instanceIDs {
		tags := aws.GetTagsForEc2Instance(t, awsRegion, id)

		nameTag, exists := tags["Name"]
		if assert.True(t, exists) {
			assert.Equal(t, namePrefix, nameTag)
		}
	}
}
