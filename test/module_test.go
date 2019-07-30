package module_test

import (
	"fmt"
	"testing"

	asg "github.com/telia-oss/terraform-aws-asg/v3/test"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestDefaultExample(t *testing.T) {
	tests := []struct {
		description string
		directory   string
		name        string
		region      string
		expected    asg.Expectations
	}{
		{
			description: "basic example",
			directory:   "../examples/basic",
			name:        fmt.Sprintf("asg-basic-test-%s", random.UniqueId()),
			region:      "eu-west-1",
			expected: asg.Expectations{
				MinSize:         1,
				MaxSize:         3,
				DesiredCapacity: 1,
				InstanceType:    "t3.micro",
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
			expected: asg.Expectations{
				MinSize:         2,
				MaxSize:         4,
				DesiredCapacity: 2,
				UserData:        []string{"#!bin/bash\necho hello world"},
				InstanceType:    "t3.micro",
				Volumes: []string{
					"/dev/xvdcz",
				},
				InstanceTags: map[string]string{
					"terraform":   "True",
					"environment": "dev",
				},
			},
		},
	}

	for _, tc := range tests {
		tc := tc // Source: https://gist.github.com/posener/92a55c4cd441fc5e5e85f27bca008721
		t.Run(tc.description, func(t *testing.T) {
			t.Parallel()
			options := &terraform.Options{
				TerraformDir: tc.directory,

				Vars: map[string]interface{}{
					"name_prefix": tc.name,
					"region":      tc.region,
				},

				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": tc.region,
				},
			}

			defer terraform.Destroy(t, options)
			terraform.InitAndApply(t, options)

			name := terraform.Output(t, options, "id")
			asg.RunTestSuite(t, name, tc.region, tc.expected)
		})
	}
}
