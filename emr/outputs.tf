output "master_public_dns" {
  value = aws_emr_cluster.cluster.*.master_public_dns
}

output "names" {
  value = aws_emr_cluster.cluster.*.name
}

