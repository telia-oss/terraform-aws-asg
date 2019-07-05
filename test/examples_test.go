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
	type expectations struct {
		MinCapacity     int64
		MaxCapacity     int64
		DesiredCapacity int64
		InstanceTags    map[string]string
	}

	tests := []struct {
		description string
		directory   string
		name        string
		region      string
		expected    expectations
	}{
		{
			description: "basic example",
			directory:   "../examples/basic",
			name:        fmt.Sprintf("asg-basic-test-%s", random.UniqueId()),
			region:      "eu-west-1",
			expected: expectations{
				MinCapacity:     1,
				MaxCapacity:     3,
				DesiredCapacity: 1,
				InstanceTags: map[string]string{
					"terraform":   "True",
					"environment": "dev",
				},
			},
		},
		{
			description: "complete example",
			directory:   "../examples/complete",
			name:        fmt.Sprintf("asg-complete-test-%s", random.UniqueId()),
			region:      "eu-west-1",
			expected: expectations{
				MinCapacity:     2,
				MaxCapacity:     4,
				DesiredCapacity: 2,
				InstanceTags: map[string]string{
					"terraform":   "True",
					"environment": "dev",
				},
			},
		},
	}

	for _, tc := range tests {
		t.Run(tc.description, func(t *testing.T) {
			options := &terraform.Options{
				TerraformDir: tc.directory,

				Vars: map[string]interface{}{
					"name_prefix": tc.name,
				},

				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": tc.region,
				},
			}

			defer terraform.Destroy(t, options)
			terraform.InitAndApply(t, options)

			// Retrieve the id (name) of the Autoscaling group.
			asgName := terraform.Output(t, options, "id")

			// Check the capacity for the ASG.
			capacity := aws.GetCapacityInfoForAsg(t, asgName, tc.region)
			assert.Equal(t, tc.expected.MinCapacity, capacity.MinCapacity)
			assert.Equal(t, tc.expected.MaxCapacity, capacity.MaxCapacity)
			assert.Equal(t, tc.expected.DesiredCapacity, capacity.DesiredCapacity)

			// Wait for capacity in the autoscaling group (max 300 seconds)
			aws.WaitForCapacity(t, asgName, tc.region, 30, 10*time.Second)

			instanceIDs := aws.GetInstanceIdsForAsg(t, asgName, tc.region)
			for _, id := range instanceIDs {
				tags := aws.GetTagsForEc2Instance(t, tc.region, id)

				name, exists := tags["Name"]
				if assert.True(t, exists) {
					assert.Equal(t, tc.name, name)
				}

				for key, want := range tc.expected.InstanceTags {
					got, exists := tags[key]
					if assert.True(t, exists) {
						assert.Equal(t, want, got)
					}
				}
			}
		})
	}
}
