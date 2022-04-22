output "environment_name" {
  description = "Environment name"
  value       = local.env_name
}

output "controller_names" {
  description = "Names of controller instance"
  value       = local.controller_names
}
output "worker_names" {
  description = "Names of controller instance"
  value       = local.worker_names
}

output "debian_ami_id" {
  description = "Debian image AMI ID"
  value       = data.aws_ami.debian.id
}

output "availability_zone" {
  description = "Deployment availability zone"
  value       = data.aws_availability_zones.available.names[0]
}
