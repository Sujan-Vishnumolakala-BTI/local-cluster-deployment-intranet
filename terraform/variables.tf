# ============================================================
# Terraform Variables
# ============================================================

variable "aws_region" {

  description = "AWS region"

  type = string

  default = "ap-south-1"
}


variable "project_name" {

  description = "Project name used for AWS resource naming"

  type = string

  default = "local-kubernetes"
}


variable "vpc_cidr" {

  description = "VPC CIDR block"

  type = string

  default = "10.0.0.0/16"
}


variable "public_subnet_cidrs" {

  description = "CIDR blocks for public subnets"

  type = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}


variable "availability_zones" {

  description = "Availability zones for the public subnets"

  type = list(string)

  default = [
    "ap-south-1a",
    "ap-south-1b",
    "ap-south-1c"
  ]
}


variable "allowed_api_cidrs" {

  description = "CIDRs allowed to access the Kubernetes API"

  type = list(string)

  default = [
    "0.0.0.0/0"
  ]
}


variable "allowed_ssh_cidrs" {

  description = "CIDRs allowed to access SSH"

  type = list(string)

  default = [
    "0.0.0.0/0"
  ]
}
