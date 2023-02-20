# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#############################################
# Setting env variables. 
# Change AWSREGION and CONSUL_LICENSE as needed
# Change EKS_CLUSTER_SERVER, EKS_CLUSTER_CLIENT1, EKS_CLUSTER_CLIENT2 if you have different EKS cluster names.
#############################################


export AWSREGION=eu-north-1
export EKS_CLUSTER_SERVER=Consul-cluster-server
export EKS_CLUSTER_CLIENT1=Consul-cluster-client1
export EKS_CLUSTER_CLIENT2=Consul-cluster-client2

export EKS_CLUSTER_SERVER_CTX=$(aws eks --region $AWSREGION update-kubeconfig --name $EKS_CLUSTER_SERVER | grep arn | awk '{print $3}')
export EKS_CLUSTER_CLIENT1_CTX=$(aws eks --region $AWSREGION update-kubeconfig --name $EKS_CLUSTER_CLIENT1 | grep arn | awk '{print $3}')
export EKS_CLUSTER_CLIENT2_CTX=$(aws eks --region $AWSREGION update-kubeconfig --name $EKS_CLUSTER_CLIENT2 | grep arn | awk '{print $3}')

export CONSUL_LICENSE=<ADD_YOUR_LICENSE_HERE>
#You can request a 30 day trial license here: https://www.hashicorp.com/products/consul/trial


#############################################
#INSTALL CONSUL CLIENT 1 ON SECOND K8S CLUSTER 
#############################################

# Copy tls cert/keys and partition acl tokens. This is needed if tls and acls are enabled.
kubectl get secret consul-consul-ca-cert --context $EKS_CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $EKS_CLUSTER_CLIENT1_CTX -f -
kubectl get secret consul-consul-ca-key --context $EKS_CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $EKS_CLUSTER_CLIENT1_CTX -f -
kubectl get secret consul-consul-partitions-acl-token --context $EKS_CLUSTER_SERVER_CTX -o json | kubectl apply --context $EKS_CLUSTER_CLIENT1_CTX -f -

# Set context, add license, install
# IMPORTANT, make sure you edited your helm-client1.yaml file with the latest partition service IPs and the current K8AuthHost. 
 
kubectl config use-context $EKS_CLUSTER_CLIENT1_CTX
kubectl create secret generic license --from-literal=key=$CONSUL_LICENSE
helm install consul hashicorp/consul -f helm-client-team1.yaml --wait --debug




