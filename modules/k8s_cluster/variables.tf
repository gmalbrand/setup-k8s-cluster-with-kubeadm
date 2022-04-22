variable "controller_number" {
  description = "Number of controller to create"
  type        = number
  default     = 1
}

variable "worker_number" {
  description = "Number of worker to create"
  type        = number
  default     = 2
}

variable "default_key_pair" {
  description = "Default AWS key pair"
  type        = string
}

variable "security_group_id" {
  description = "Id to the security group for instances"
  type        = string
}
