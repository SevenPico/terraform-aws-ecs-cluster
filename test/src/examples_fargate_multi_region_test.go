package test

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// Test the Fargate multi-region examples
func TestExamplesFargateMultiRegion(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	globalTerraformFolderRelativeToRoot := "examples/fargate-multi-region-global"
	secondaryTerraformFolderRelativeToRoot := "examples/fargate-multi-region-secondary"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	// Copy both examples to temp folders
	tempGlobalTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, globalTerraformFolderRelativeToRoot)
	tempSecondaryTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, secondaryTerraformFolderRelativeToRoot)

	// Global region terraform options
	globalTerraformOptions := &terraform.Options{
		TerraformDir: tempGlobalTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    "true",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, globalTerraformOptions, tempGlobalTestFolder)

	// Deploy global region first
	terraform.InitAndApply(t, globalTerraformOptions)

	// Get the IAM role name from global region
	globalRoleName := terraform.Output(t, globalTerraformOptions, "role_name")
	assert.NotEmpty(t, globalRoleName, "Global region should output a role name")

	// Secondary region terraform options
	secondaryTerraformOptions := &terraform.Options{
		TerraformDir: tempSecondaryTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes":           attributes,
			"enabled":              "true",
			"global_iam_role_name": globalRoleName,
		},
	}

	defer cleanup(t, secondaryTerraformOptions, tempSecondaryTestFolder)

	// Deploy secondary region using the global IAM role
	terraform.InitAndApply(t, secondaryTerraformOptions)

	// Verify outputs from both regions
	globalClusterName := terraform.Output(t, globalTerraformOptions, "name")
	secondaryClusterName := terraform.Output(t, secondaryTerraformOptions, "name")
	secondaryRoleName := terraform.Output(t, secondaryTerraformOptions, "role_name")

	// Both clusters should be created with the expected naming
	assert.Contains(t, globalClusterName, randID)
	assert.Contains(t, secondaryClusterName, randID)

	// Secondary region should use the same IAM role as global
	assert.Equal(t, globalRoleName, secondaryRoleName, "Secondary region should use the same IAM role as global")
}
