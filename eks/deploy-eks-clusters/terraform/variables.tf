# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

##########################
# Desired network config
##########################

variable "eks-vpc-id" {
  description = "VPC ID of desired VPC"
  type        = string
  default     = "<Your-VPC-ID>"
}

variable "aws-region" {
  description = "Desired aws region, ex: eu-north-1"
  type        = string
  default     = "Your-AWS-region"
}

variable "eks-subnet-id-1" {
  description = "desired subnet ID"
  type        = string
  default     = "<Your-first-subnet-ID>"
}

variable "eks-subnet-id-2" {
  description = "desired subnet ID"
  type        = string
  default     = "<Your-second-subnet-ID>"
}

variable "eks-subnet-id-3" {
  description = "desired subnet ID"
  type        = string
  default     = "<Your-third-subnet-ID>"
}

variable "security-group-open" {
  description = "for testing/demo purposes, this is a sec group allowing all traffic to flow between in and out of eks worker nodes."
  type        = string
  default     = "<Your-security-group-ID>"
}


############################
# Desired EKS cluster names
############################


variable "eks-cluster-server-name" {
  description = "Name of eks server cluster"
  type        = string
  default     = "Consul-cluster-server"
}

variable "eks-cluster-client1-name" {
  description = "Name of second eks client cluster"
  type        = string
  default     = "Consul-cluster-client1"
}

variable "eks-cluster-client2-name" {
  description = "Name of first eks client cluster"
  type        = string
  default     = "Consul-cluster-client2"
}




