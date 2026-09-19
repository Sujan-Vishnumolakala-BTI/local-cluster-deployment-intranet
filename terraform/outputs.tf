# ============================================================
# Terraform Outputs
# ============================================================

output "vpc_id" {

  description = "Kubernetes VPC ID"

  value = aws_vpc.kubernetes.id
}


output "vpc_cidr" {

  description = "Kubernetes VPC CIDR"

  value = aws_vpc.kubernetes.cidr_block
}


output "internet_gateway_id" {

  description = "Internet Gateway ID"

  value = aws_internet_gateway.kubernetes.id
}


output "public_subnet_ids" {

  description = "Public subnet IDs"

  value = aws_subnet.public[*].id
}


output "public_subnet_cidrs" {

  description = "Public subnet CIDR blocks"

  value = aws_subnet.public[*].cidr_block
}


output "load_balancer_arn" {

  description = "Network Load Balancer ARN"

  value = aws_lb.kubernetes.arn
}


output "load_balancer_dns_name" {

  description = "Network Load Balancer DNS name"

  value = aws_lb.kubernetes.dns_name
}


output "kubernetes_api_endpoint" {

  description = "Kubernetes API endpoint"

  value = "${aws_lb.kubernetes.dns_name}:6443"
}


output "kubernetes_api_target_group_arn" {

  description = "Kubernetes API target group ARN"

  value = aws_lb_target_group.kubernetes_api.arn
}
