# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


############################################################################
# Create EKS three Clusters, Consul Server, Consul Client 1, Consul Client 2
############################################################################



module "eks-consul-servers" {
  source = "./modules/eks-cluster-create"
  cluster_name = var.eks-cluster-server-name
  vpc_id = var.eks-vpc-id
  aws_region= var.aws-region
  subnet-id-1 = var.eks-subnet-id-1
  subnet-id-2 = var.eks-subnet-id-2
  subnet-id-3 = var.eks-subnet-id-3
  sec-group-eks-nodes = var.security-group-open
} 


module "eks-consul-client1" {
  source = "./modules/eks-cluster-create"
  cluster_name = var.eks-cluster-client1-name
  vpc_id = var.eks-vpc-id
  aws_region= var.aws-region
  subnet-id-1 = var.eks-subnet-id-1
  subnet-id-2 = var.eks-subnet-id-2
  subnet-id-3 = var.eks-subnet-id-3
  sec-group-eks-nodes = var.security-group-open
}

module "eks-consul-client2" {
  source = "./modules/eks-cluster-create"
  cluster_name = var.eks-cluster-client2-name
  vpc_id = var.eks-vpc-id
  aws_region= var.aws-region
  subnet-id-1 = var.eks-subnet-id-1
  subnet-id-2 = var.eks-subnet-id-2
  subnet-id-3 = var.eks-subnet-id-3
  sec-group-eks-nodes = var.security-group-open
}

###################################################
# Create a New Security Group - Open for testing purposes
##################################################


#Create Security Group, not used right now but will incorporate later
#
#resource "aws_security_group" "allow-all" {
#  name        = "allow-all-TF-test"
#  description = "Allow all traffic"
#  vpc_id      = var.eks-vpc-id
#
#  ingress {
#    description      = "open"
#    from_port        = 0
#    to_port          = 0
#    protocol         = "-1"
#    cidr_blocks      = ["0.0.0.0/0"]
#  }
#
#  egress {
#    from_port        = 0
#    to_port          = 0
#    protocol         = "-1"
#    cidr_blocks      = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "allow_all_TF"
#  }
#}


