package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// Test the Fargate multi-region examples
func TestExamplesFargateMultiRegion(t *testing.T) {
	// Remove t.Parallel() to avoid resource conflicts with other tests
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	globalTerraformFolderRelativeToRoot := "examples/fargate-multi-region-global"
	secondaryTerraformFolderRelativeToRoot := "examples/fargate-multi-region-secondary"
	globalVarFiles := []string{"fixtures.us-east-2.tfvars"}
	secondaryVarFiles := []string{"fixtures.us-west-2.tfvars"}

	// Copy both examples to temp folders
	tempGlobalTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, globalTerraformFolderRelativeToRoot)
	tempSecondaryTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, secondaryTerraformFolderRelativeToRoot)

	// Global region terraform options (us-east-2)
	globalTerraformOptions := &terraform.Options{
		TerraformDir: tempGlobalTestFolder,
		Upgrade:      true,
		VarFiles:     globalVarFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    "true",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, globalTerraformOptions, tempGlobalTestFolder)

	// Deploy global region first
	terraform.InitAndApply(t, globalTerraformOptions)

	// Secondary region terraform options (us-west-2 - different region)
	secondaryTerraformOptions := &terraform.Options{
		TerraformDir: tempSecondaryTestFolder,
		Upgrade:      true,
		VarFiles:     secondaryVarFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    "true",
		},
	}

	defer cleanup(t, secondaryTerraformOptions, tempSecondaryTestFolder)

	// Deploy secondary region independently (Fargate clusters are independent)
	terraform.InitAndApply(t, secondaryTerraformOptions)

	// Verify outputs from both regions
	globalClusterName := terraform.Output(t, globalTerraformOptions, "name")
	secondaryClusterName := terraform.Output(t, secondaryTerraformOptions, "name")

	// Both clusters should be created with the expected naming
	assert.Contains(t, globalClusterName, randID)
	assert.Contains(t, secondaryClusterName, randID)

	// Verify both clusters are independent Fargate clusters
	globalClusterArn := terraform.Output(t, globalTerraformOptions, "arn")
	secondaryClusterArn := terraform.Output(t, secondaryTerraformOptions, "arn")
	
	assert.NotEmpty(t, globalClusterArn, "Global cluster should have an ARN")
	assert.NotEmpty(t, secondaryClusterArn, "Secondary cluster should have an ARN")
	assert.NotEqual(t, globalClusterArn, secondaryClusterArn, "Clusters should be independent with different ARNs")
}
