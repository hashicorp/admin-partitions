# Steps to configure Admin Partitions on yourAzure  HCP Consul deployment 
This repo will guide you through configuring Administrative Partition on HCP Consul Azure. 
Admin Partition is Consul's multi-tenancy feature allowing full isolation between teams on both the administrative and network level.   
We will connect two AKS clusters as Consul clients to an HCP Consul cluster. Each AKS cluster will represent a different team.


For your reference, many of these steps similar to the Azure HCP tutorial on [Learn](https://learn.hashicorp.com/tutorials/cloud/consul-client-aks?in=cloud/consul-cloud).  
If you deployed HCP Consul from the HCP Web UI the steps in this repo are similar if you click on **Start from HCP Portal**.

![HCP](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-08-22%20at%2011.31.07%20AM.png)


# Pre-Reqs

1. This repo assume that you have already deployed an Azure HCP Consul cluster. It is very straight forward. You can deploy one using the HCP Consul portal or via Terraform. Both options are provided from the [HCP Consul portal](https://portal.cloud.hashicorp.com/sign-up?utm_source=cloud_landing&utm_content=offers_consul&_gl=1*1bv5r1c*_ga*MjAyNzgyNjAxLjE2NDA4MTEzOTQ.*_ga_P7S46ZYEKW*MTY2MTE5MTA1Mi42Ny4xLjE2NjExOTIwMDUuMC4wLjA.).
2. Ensure you followed provided steps to peer network connections between the HCP HashiCorp Vritual network (HVN) and your own VNET.
3. Ensure you have followed provided steps to route traffic through your peering connections.
4. Deploy 2 AKS clusters in your Azure envronments. Make sure when you create your AKS clusters that you are selecting the Azure CNI (instead of Kubenet)

# Deploy Consul Clients on AKS

Once your HCP Consul isa deployed and you've peered and routed your VNET, you can start configuring your Consul clients to the HCP Consul Cluster.

1. Login from your terminal to your Azure account. 
```
az login
```

2. Connect your local machine's terminal to your AKS cluster.
```
az aks get-credentials --resource-group <Your-Azure-Resource-Group> --name <Your-first-AKS-cluster>
```
```
az aks get-credentials --resource-group <Your-Azure-Resource-Group> --name <Your-second-AKS-cluster>
```

3. Set environment variables for your two AKS clusters.
```
export CLUSTER_CLIENT1_CTX=<Your_First_AKS_Cluster>
export CLUSTER_CLIENT2_CTX=<Your_Second_AKS_Cluster>
```

4. On the HCP portal, go to your HCP Consul cluster and download the client files.  
You can click the **Access Consul** dropdown and then click **Download to install Client Agents** to download a zip archive that contains the necessary files to join your client agents to the cluster.  


![Client download](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-08-22%20at%2012.45.14%20PM.png)

5. Unzip the client config package into the current working directory, and then use ls to confirm that both the client_config.json and ca.pem files are available.
```
ls
ca.pem             client_config.json
```

6. Under “Access your cluster over the public internet", click the copy icon. The HCP Consul dashboard UI link is now in your clipboard. Set this token to the CONSUL_HTTP_ADDR environment variable on your development host so that you can reference it later in the tutorial.
![hcp](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-08-22%20at%201.00.26%20PM.png)
