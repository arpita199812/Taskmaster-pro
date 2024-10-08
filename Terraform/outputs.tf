output "cluster_id" {
  value = aws_eks_cluster.taskpro_cluster.id
}

output "node_group_id" {
  value = aws_eks_node_group.taskpro_ng.id
}

output "vpc_id" {
  value = aws_vpc.taskpro_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.taskpro_subnet[*].id
}
