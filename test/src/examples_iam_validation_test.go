package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// Test IAM validation scenarios
func TestExamplesIAMValidation(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/ec2-multi-region-secondary"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	// Test 1: Validation should fail when create_iam_role is false but global_iam_role_name is not provided
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    "true",
			// Missing global_iam_role_name - this should fail validation
		},
	}

	// This should fail during plan/validate
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Should fail validation when global_iam_role_name is not provided")

	// Test 2: Validation should fail with invalid IAM role name
	terraformOptions.Vars["global_iam_role_name"] = "invalid@role#name!"

	_, err = terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Should fail validation with invalid IAM role name")

	// Test 3: Should succeed with valid configuration (but will fail at apply due to non-existent role)
	terraformOptions.Vars["global_iam_role_name"] = "valid-role-name-" + randID

	// This should succeed at plan but fail at apply due to non-existent role
	terraform.InitAndPlan(t, terraformOptions)

	// Don't actually apply since the role doesn't exist - just verify plan succeeds
}

// Test that existing IAM role validation works
func TestExamplesExistingIAMRoleValidation(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/ec2-multi-region-secondary"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	// Test with non-existent IAM role
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes":           attributes,
			"enabled":              "true",
			"global_iam_role_name": "non-existent-role-" + randID,
		},
	}

	// This should fail during apply when trying to find the non-existent role
	_, err := terraform.InitAndApplyE(t, terraformOptions)
	assert.Error(t, err, "Should fail when trying to use non-existent IAM role")
	// The error message might vary, so just check that it failed
	assert.NotNil(t, err, "Should get error for non-existent role")

	// Clean up any partial resources
	terraform.Destroy(t, terraformOptions)
}
