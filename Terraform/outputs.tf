output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.main.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "route_table_id" {
  value = aws_route_table.main.id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "ec2_instance_id" {
  value = aws_instance.my_instance.id
}
