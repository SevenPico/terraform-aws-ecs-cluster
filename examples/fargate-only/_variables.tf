variable "region" {
  type        = string
  description = "AWS Region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "container_insights_enabled" {
  description = "Whether or not to enable container insights"
  type        = bool
  default     = true
}

variable "capacity_providers_fargate" {
  description = "Use FARGATE capacity provider"
  type        = bool
  default     = true
}

variable "capacity_providers_fargate_spot" {
  description = "Use FARGATE_SPOT capacity provider"
  type        = bool
  default     = true
}

variable "capacity_providers_ec2" {
  description = "EC2 autoscale groups capacity providers"
  type        = map(any)
  default     = {}
}

variable "external_ec2_capacity_providers" {
  description = "External EC2 autoscale groups capacity providers"
  type        = map(any)
  default     = {}
}

variable "create_iam_role" {
  type        = bool
  description = "Whether to create IAM role and instance profile for ECS instances"
  default     = false
}

variable "existing_iam_role_name" {
  type        = string
  description = "Name of existing IAM role to use when create_iam_role is false"
  default     = null
}

variable "policy_document" {
  description = "A list of IAM policy documents (JSON) to attach inline to the role"
  type        = list(string)
  default     = []
}
