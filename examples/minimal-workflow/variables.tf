variable "github_organization_name" {
  type        = string
  description = "The name of the GitHub organization."
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "The location/region where the resources will be created."
}
