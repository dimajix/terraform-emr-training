output "master_public_dns" {
  value = aws_emr_cluster.cluster.*.master_public_dns
}

output "master_security_group_id" {
  value = aws_security_group.master.id
}

output "names" {
  value = aws_emr_cluster.cluster.*.name
}

