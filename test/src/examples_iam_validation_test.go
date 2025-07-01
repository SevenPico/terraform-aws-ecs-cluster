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
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	// Test 1: Validation should fail when create_iam_role is false but existing_iam_role_name is not provided
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes":     attributes,
			"enabled":        "true",
			"create_iam_role": false,
			// Missing existing_iam_role_name
		},
	}

	// This should fail during plan/validate
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Should fail validation when create_iam_role is false but existing_iam_role_name is not provided")
	assert.Contains(t, err.Error(), "existing_iam_role_name must be provided when create_iam_role is false")

	// Test 2: Validation should fail with invalid IAM role name
	terraformOptions.Vars["existing_iam_role_name"] = "invalid@role#name!"

	_, err = terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Should fail validation with invalid IAM role name")
	assert.Contains(t, err.Error(), "existing_iam_role_name must be a valid IAM role name")

	// Test 3: Should succeed with valid configuration
	terraformOptions.Vars["create_iam_role"] = true
	delete(terraformOptions.Vars, "existing_iam_role_name")

	defer cleanup(t, terraformOptions, tempTestFolder)

	// This should succeed
	terraform.InitAndApply(t, terraformOptions)

	// Verify outputs
	roleName := terraform.Output(t, terraformOptions, "role_name")
	roleArn := terraform.Output(t, terraformOptions, "role_arn")
	instanceProfile := terraform.Output(t, terraformOptions, "role_instance_profile")

	assert.NotEmpty(t, roleName, "Should output role name")
	assert.NotEmpty(t, roleArn, "Should output role ARN")
	assert.NotEmpty(t, instanceProfile, "Should output instance profile")
	assert.Contains(t, roleArn, roleName, "Role ARN should contain role name")
}

// Test that existing IAM role validation works
func TestExamplesExistingIAMRoleValidation(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	// Test with non-existent IAM role
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes":              attributes,
			"enabled":                 "true",
			"create_iam_role":         false,
			"existing_iam_role_name":  "non-existent-role-" + randID,
		},
	}

	// This should fail during apply when trying to find the non-existent role
	_, err := terraform.InitAndApplyE(t, terraformOptions)
	assert.Error(t, err, "Should fail when trying to use non-existent IAM role")
	assert.Contains(t, err.Error(), "NoSuchEntity", "Should get NoSuchEntity error for non-existent role")

	// Clean up any partial resources
	terraform.Destroy(t, terraformOptions)
}
