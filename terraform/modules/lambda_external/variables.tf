variable "function_name" {
  type = string
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
