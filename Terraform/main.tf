terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.65.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "taskpro_vpc" {
  cidr_block    = "10.0.0.0/16"

  tags = {
    Name = "taskpro-vpc"
  }
}

resource "aws_internet_gateway" "taskpro_igw" {
  vpc_id = aws_vpc.taskpro_vpc.id
  tags = {
    Name = "taskpro-igw"
  }
}

resource "aws_route_table" "taskpro_rt" {
  vpc_id = aws_vpc.taskpro_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.taskpro_igw.id
  }

  tags = {
    Name = "taskpro-route-table"
  }
}

resource "aws_subnet" "taskpro_subnet" {
  count = 2
  vpc_id                  = aws_vpc.taskpro_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.taskpro_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "taskpro-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.taskpro_subnet[count.index].id
  route_table_id = aws_route_table.taskpro_rt.id
}

resource "aws_security_group" "taskpro_cluster_sg" {
  vpc_id = aws_vpc.taskpro_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskpro-cluster-sg"
  }
}

resource "aws_security_group" "taskpro_node_sg" {
  vpc_id = aws_vpc.taskpro_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskpro-node-sg"
  }
}

resource "aws_eks_cluster" "taskpro_cluster" {
  name     = "taskpro-cluster"
  role_arn = aws_iam_role.taskpro_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.taskpro_subnet[*].id
    security_group_ids = [aws_security_group.taskpro_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "taskpro_ng" {
  cluster_name    = aws_eks_cluster.taskpro_cluster.name
  node_group_name = "taskpro-node-group"
  node_role_arn   = aws_iam_role.taskpro_node_group_role.arn
  subnet_ids      = aws_subnet.taskpro_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.large"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.taskpro_node_sg.id]
  }
}

resource "aws_iam_role" "taskpro_cluster_role" {
  name = "taskpro-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "taskpro_cluster_role_policy" {
  role       = aws_iam_role.taskpro_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "taskpro_node_group_role" {
  name = "taskpro-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "taskpro_node_group_role_policy" {
  role       = aws_iam_role.taskpro_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "taskpro_node_group_cni_policy" {
  role       = aws_iam_role.taskpro_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "taskpro_node_group_registry_policy" {
  role       = aws_iam_role.taskpro_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
