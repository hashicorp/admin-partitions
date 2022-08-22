# Steps to configure Admin Partitions on yourAzure  HCP Consul deployment 
This repo will guide you through configuring Administrative Partition on HCP Consul Azure. 
Admin Partition is Consul's multi-tenancy feature allowing full isolation between teams on both the administrative and network level.   

For your reference, many of these steps similar to the Azure HCP tutorial on [Learn](https://learn.hashicorp.com/tutorials/cloud/consul-client-aks?in=cloud/consul-cloud).

# Pre-Reqs

1. This repo assume that you have already deployed an Azure HCP Consul cluster. It is very straight forward. You can deploy one using the HCP Web GUI or via Terraform. Both options are provided from the [HCP Consul portal](https://portal.cloud.hashicorp.com/sign-up?utm_source=cloud_landing&utm_content=offers_consul&_gl=1*1bv5r1c*_ga*MjAyNzgyNjAxLjE2NDA4MTEzOTQ.*_ga_P7S46ZYEKW*MTY2MTE5MTA1Mi42Ny4xLjE2NjExOTIwMDUuMC4wLjA.).
2. Ensure you followed provided steps to peer network connections between the HCP HashiCorp Vritual network (HVN) and your own VNET.
3. Ensure you have followed provided steps to route traffic through your peering connections.

# Deploy Consul Clients on AKS

Once your 

1. 
