variable "function_name" {
  type = string
}

variable "publish" {
  type    = bool
  default = true
}

variable "alias_name" {
  type    = string
  default = "LIVE"
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

variable "filename" {
  type = string
}

variable "source_code_hash" {
  type = string
}

variable "layers" {
  type    = list(string)
  default = []
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}
