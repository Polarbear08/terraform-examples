# ip address
output "public_ip" {
  description = "Public IP of launced instance"
  value       = data.aws_instance.sample02-instances.public_ip
}
