# ============================================================
# Local Kubernetes Cluster Deployment
# Terraform - AWS Infrastructure
# ============================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


# ============================================================
# AWS Provider
# ============================================================

provider "aws" {
  region = var.aws_region
}


# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "kubernetes" {

  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}


# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "kubernetes" {

  vpc_id = aws_vpc.kubernetes.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}


# ============================================================
# Public Subnets
# ============================================================

resource "aws_subnet" "public" {

  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.kubernetes.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-${count.index + 1}"
    Project = var.project_name
    Tier    = "public"
  }
}


# ============================================================
# Route Table
# ============================================================

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.kubernetes.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.kubernetes.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}


# ============================================================
# Route Table Association
# ============================================================

resource "aws_route_table_association" "public" {

  count = length(aws_subnet.public)

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}


# ============================================================
# Security Group
# ============================================================

resource "aws_security_group" "kubernetes_lb" {

  name = "${var.project_name}-lb-sg"

  description = "Security group for Kubernetes API load balancer"

  vpc_id = aws_vpc.kubernetes.id

  # Kubernetes API
  ingress {
    description = "Kubernetes API"

    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"

    cidr_blocks = var.allowed_api_cidrs
  }

  # SSH
  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = var.allowed_ssh_cidrs
  }

  # Outbound traffic
  egress {
    description = "Allow outbound traffic"

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-lb-sg"
    Project = var.project_name
  }
}


# ============================================================
# Network Load Balancer
# ============================================================

resource "aws_lb" "kubernetes" {

  name = "${var.project_name}-nlb"

  load_balancer_type = "network"

  internal = false

  subnets = aws_subnet.public[*].id

  tags = {
    Name    = "${var.project_name}-nlb"
    Project = var.project_name
  }
}


# ============================================================
# Kubernetes API Target Group
# ============================================================

resource "aws_lb_target_group" "kubernetes_api" {

  name = "${var.project_name}-api"

  port = 6443

  protocol = "TCP"

  target_type = "instance"

  vpc_id = aws_vpc.kubernetes.id

  health_check {
    protocol = "TCP"

    port = "6443"

    interval = 10

    timeout = 5

    healthy_threshold = 2

    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-api-target"
    Project = var.project_name
  }
}


# ============================================================
# Kubernetes API Listener
# ============================================================

resource "aws_lb_listener" "kubernetes_api" {

  load_balancer_arn = aws_lb.kubernetes.arn

  port = 6443

  protocol = "TCP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.kubernetes_api.arn
  }
}
