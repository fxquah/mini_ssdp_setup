variable "function_name" {
  type = string
}

variable "role" {
  type = string
}

variable "timeout" {
  type    = number
  default = 30
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

variable "publish" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "filename" {
  description = "Path to the Lambda deployment package zip"
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package"
  type        = string
}
