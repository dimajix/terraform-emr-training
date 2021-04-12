output "master_public_dns" {
  value = aws_emr_cluster.cluster.*.master_public_dns
}

output "master_private_ip" {
  description = "Private IP of master node"
  value = data.aws_instance.cluster.*.private_ip
}

output "master_private_dns" {
  description = "Private DNS of master node"
  value = data.aws_instance.cluster.*.private_dns
}

output "master_security_group_id" {
  value = aws_security_group.master.id
}

output "names" {
  value = aws_emr_cluster.cluster.*.name
}

