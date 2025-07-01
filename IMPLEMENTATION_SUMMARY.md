# Multi-Region IAM Support Implementation Summary

This document summarizes the implementation of optional IAM resource creation for multi-region ECS cluster deployments.

## Overview

Added support for optional IAM resource creation to enable multi-region deployments where:
- **Global Region**: Creates IAM resources + ECS cluster
- **Secondary Regions**: Reuse existing IAM resources + create ECS cluster

## Changes Made

### 1. Core Module Updates

#### Variables (`_variables.tf`)
- Added `create_iam_role` (bool, default: true) - Controls IAM resource creation
- Added `existing_iam_role_name` (string) - Name of existing IAM role when `create_iam_role = false`
- Added validation to ensure `existing_iam_role_name` is provided when `create_iam_role = false`
- Added validation for IAM role name format

#### IAM Resources (`iam.tf`)
- Made IAM role module conditional based on `create_iam_role`
- Added data sources for existing IAM resources:
  - `aws_iam_role.existing` - Lookup existing role by name
  - `aws_iam_instance_profiles_for_role.existing` - Auto-discover instance profiles
  - Policy attachment validation for existing roles
- Added local values to abstract conditional logic:
  - `local.role_name` - Role name (created or existing)
  - `local.role_arn` - Role ARN (created or existing)  
  - `local.instance_profile_name` - Instance profile name (created or existing)

#### EC2 Integration (`ec2.tf`)
- Updated autoscaling group to use `local.instance_profile_name` instead of `module.role.name`

#### Outputs (`_outputs.tf`)
- Updated outputs to use local values instead of direct module references
- Fixed output descriptions (were incorrectly labeled)

### 2. New Examples

Created 4 new example configurations demonstrating multi-region patterns:

#### EC2 Examples
- `examples/ec2-multi-region-global/` - Creates IAM + EC2 ECS cluster
- `examples/ec2-multi-region-secondary/` - Uses existing IAM + EC2 ECS cluster

#### Fargate Examples  
- `examples/fargate-multi-region-global/` - Creates IAM + Fargate ECS cluster
- `examples/fargate-multi-region-secondary/` - Uses existing IAM + Fargate ECS cluster

Each example includes:
- Complete Terraform configuration
- Context, variables, outputs, and versions files
- Fixture files for testing

### 3. Test Coverage

Added comprehensive test suites:

#### `test/src/examples_ec2_multi_region_test.go`
- Tests EC2 multi-region deployment pattern
- Validates global region creates IAM role
- Validates secondary region reuses IAM role
- Confirms both clusters use same IAM role

#### `test/src/examples_fargate_multi_region_test.go`
- Tests Fargate multi-region deployment pattern
- Same validation logic as EC2 tests

#### `test/src/examples_iam_validation_test.go`
- Tests validation scenarios:
  - Fails when `create_iam_role = false` but no `existing_iam_role_name`
  - Fails with invalid IAM role name format
  - Succeeds with valid configuration
  - Fails when referencing non-existent IAM role

## Usage Patterns

### Global Region (Creates IAM)
```hcl
module "ecs_cluster" {
  source = "SevenPico/ecs-cluster/aws"
  
  # Standard configuration
  create_iam_role = true  # Default
}
```

### Secondary Region (Reuses IAM)
```hcl
data "aws_iam_role" "global_role" {
  name = "my-global-ecs-role"
}

module "ecs_cluster" {
  source = "SevenPico/ecs-cluster/aws"
  
  # Use existing IAM role
  create_iam_role        = false
  existing_iam_role_name = data.aws_iam_role.global_role.name
}
```

## Key Features

✅ **Backwards Compatible** - No breaking changes to existing usage  
✅ **Automatic Discovery** - Instance profiles discovered automatically from role name  
✅ **Built-in Validation** - Ensures required policies are attached to existing roles  
✅ **Multi-Region Ready** - Supports both EC2 and Fargate capacity providers  
✅ **Comprehensive Testing** - Full test coverage for new functionality  
✅ **Clean Abstraction** - Local values hide complexity from module consumers  

## Validation Features

- **Input Validation**: Ensures `existing_iam_role_name` provided when needed
- **Format Validation**: Validates IAM role name format
- **Policy Validation**: Checks existing roles have required ECS policies attached:
  - `AmazonEC2ContainerServiceforEC2Role`
  - `AmazonSSMManagedInstanceCore`
- **Runtime Validation**: Fails gracefully if referenced IAM role doesn't exist

## Benefits

1. **Cost Optimization**: Avoid duplicate IAM resources across regions
2. **Simplified Management**: Single IAM role to manage across regions  
3. **Compliance**: Easier to audit and manage permissions centrally
4. **Flexibility**: Can mix and match regions with different IAM strategies
5. **Future-Proof**: Works with both current and future capacity provider types
