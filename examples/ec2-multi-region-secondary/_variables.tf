variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones IDs (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)"
}

variable "global_iam_role_name" {
  type        = string
  description = "Name of the IAM role created in the global region"
}
