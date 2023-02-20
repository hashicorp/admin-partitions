# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#
# This file is modeled from the usage example link: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest#usage-example
# I also leveraged part of the example from this link: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/managed_node_groups/main.tf

#Declare region variable, input coming from main.tf file.

variable "aws_region" {
  description = "desired aws region "
  type        = string
  default     = "eks-cluster-server"
}

provider "aws" {
  region = var.aws_region
}


#locals {
#  name            = "van-eks-${random_string.suffix.result}"
#  cluster_version = "1.21"
#  region          = "eu-north-1"
#}

################################################################################
# Kubernetes provider configuration
################################################################################

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}


################################################################################
# EKS Module
################################################################################


#Declare variables, input coming from main.tf file.

variable "cluster_name" {
  description = "Value of the name of eks cluster"
  type        = string
  default     = "eks-cluster-server"
}

variable "vpc_id" {
  description = "VPC ID of desired VPC"
  type        = string
}

variable "subnet-id-1" {
  description = "desired subnet ID"
  type        = string
  default     = null
}

variable "subnet-id-2" {
  description = "desired subnet ID"
  type        = string
  default     = null
}

variable "subnet-id-3" {
  description = "desired subnet ID"
  type        = string
  default     = null
}

variable "sec-group-eks-nodes" {
  description = "for testing/demo purposes, this is a sec group allowing all traffic to flow between in and out of eks worker nodes."
  type        = string
  default     = null
}



module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_version = "1.21"
  cluster_name    = var.cluster_name
  vpc_id  = var.vpc_id
  subnets = [var.subnet-id-1, var.subnet-id-2, var.subnet-id-3]
  worker_groups = [
    {
      instance_type = "t3.medium"
      asg_max_size  = 3
      asg_desired_capacity = 3
      additional_security_group_ids = var.sec-group-eks-nodes
    }
  ]
}


################################################################################
# Supporting Resources
################################################################################

resource "random_string" "suffix" {
  length  = 8
  special = false
}



