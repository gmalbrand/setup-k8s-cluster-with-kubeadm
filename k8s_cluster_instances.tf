provider "aws" {
}


variable "default_key_pair" {
  description = "Default AWS key pair"
  type        = string
}

variable "security_group_id" {
  description = "Id to the security group for instances"
  type        = string
}



module "k8s_cluster" {
  source            = "./modules/k8s_cluster"
  default_key_pair  = var.default_key_pair
  security_group_id = var.security_group_id
}
