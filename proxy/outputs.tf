output "security_group_id" {
  value = aws_security_group.proxy.id
}

output "public_dns" {
  value = aws_instance.proxy.public_dns
}
