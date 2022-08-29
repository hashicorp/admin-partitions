# Steps to configure Admin Partitions on yourAzure  HCP Consul deployment 
This repo will guide you through configuring Administrative Partition on HCP Consul Azure. 
Admin Partition is Consul's multi-tenancy feature allowing full isolation between teams on both the administrative and network level.   
We will connect two AKS clusters as Consul clients to an HCP Consul cluster. Each AKS cluster will represent a different team.


For your reference, many of these steps similar to the Azure HCP tutorial on [Learn](https://learn.hashicorp.com/tutorials/cloud/consul-client-aks?in=cloud/consul-cloud#configure-development-host).  
If you deployed HCP Consul from the HCP Web UI the steps in this repo are similar if you click on **Start from HCP Portal**.

![HCP](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-08-22%20at%2011.31.07%20AM.png)


# Pre-Reqs

1. This repo assume that you have already deployed an Azure HCP Consul cluster. It is very straight forward. You can deploy one using the HCP Consul portal or via Terraform. Both options are provided from the [HCP Consul portal](https://portal.cloud.hashicorp.com/sign-up?utm_source=cloud_landing&utm_content=offers_consul&_gl=1*1bv5r1c*_ga*MjAyNzgyNjAxLjE2NDA4MTEzOTQ.*_ga_P7S46ZYEKW*MTY2MTE5MTA1Mi42Ny4xLjE2NjExOTIwMDUuMC4wLjA.).  
  Note: This [Learn guide](https://learn.hashicorp.com/tutorials/cloud/consul-client-aks?in=cloud/consul-cloud) can walk you through the steps of setting up HCP Consul on Azure.
2. Ensure you followed provided steps to peer network connections between the HCP HashiCorp Vritual network (HVN) and your own VNET.
3. Ensure you have followed provided steps to route traffic through your peering connections.
4. Deploy 2 AKS clusters in your Azure envronments. Make sure when you create your AKS clusters that you are selecting the **Azure CNI** (instead of Kubenet)
5. Ensure you have helm installed on your machine. We will use helm to install the Consul clients to your AKS clusters.

# Deploy Consul Clients on AKS

Once your HCP Consul isa deployed and you've peered and routed your VNET, you can start configuring your Consul clients to the HCP Consul Cluster.


1. Clone this repo.

```
git clone https://github.com/hashicorp/admin-partitions.git
```

2. Navigate to the ```/admin-partitions/aks/deploy-on-hcp-consul-azure-aks``` directory.
```
cd /admin-partitions/aks/deploy-on-hcp-consul-azure-aks
```




3. Login from your terminal to your Azure account. 
```
az login
```

4. Connect your local machine's terminal to your two AKS clusters.

First AKS cluster:
```
az aks get-credentials --resource-group <Your-Azure-Resource-Group> --name <Your-first-AKS-cluster>
```
Second AKS cluster:
```
az aks get-credentials --resource-group <Your-Azure-Resource-Group> --name <Your-second-AKS-cluster>
```

5. Set environment variables for your two AKS clusters.
```
export CLUSTER_CLIENT1_CTX=<Your_First_AKS_Cluster>
export CLUSTER_CLIENT2_CTX=<Your_Second_AKS_Cluster>
```

6. On the HCP portal, go to your HCP Consul cluster and download the client files.  
You can click the **Access Consul** dropdown and then click **Download to install Client Agents** to download a zip archive that contains the necessary files to join your client agents to the cluster.  


![Client download](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-08-22%20at%2012.45.14%20PM.png)

7. Unzip the client config package and use **ls** to confirm that both the client_config.json and ca.pem files are available.  
  Then copy files into your ```/admin-partitions/aks/deploy-on-hcp-consul-azure-aks``` working directory.  
  

8. On the HCP portal, go to your HCP Consul cluster. 

![hcp](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-08-22%20at%201.00.26%20PM.png)

- Click on **Access Consul**. 
- Click on **Public**
- Under **Access your cluster over the public internet**, click the copy icon.  

The HCP Consul dashboard UI link is now in your clipboard. Set this UI link to the CONSUL_HTTP_ADDR environment variable on your terminal so that you can reference it later in the tutorial.  

```
export CONSUL_HTTP_ADDR=<Consul_dashboard_ui_link>
```

9. On the HCP portal, go to your HCP Consul cluster.  

![hcp-admin-token](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-08-22%20at%201.17.50%20PM.png)


- Click on **Access Consul**. 
- Select **Generate admin token** and then click the copy icon from the dialog box. 
- A global-management root token is now in your clipboard. 
 
Set this token to the CONSUL_HTTP_TOKEN environment variable on your terminal so that you can reference it later in the tutorial.

```
export CONSUL_HTTP_TOKEN=<Consul_root_token>
```

10. Use the ca.pem file in the current working directory to create a Kubernetes secret to store the Consul CA certificate. We will run this for both AKS clusters.
```
kubectl create secret generic "consul-ca-cert" --from-file='tls.crt=./ca.pem' --context $CLUSTER_CLIENT1_CTX
```
```
kubectl create secret generic "consul-ca-cert" --from-file='tls.crt=./ca.pem' --context $CLUSTER_CLIENT2_CTX
```


11. The Consul gossip encryption key is embedded in the client_config.json file that you downloaded and extracted into your current directory. Issue the following command to create a Kubernetes secret that stores the Consul gossip key encryption key. The following command uses jq to extract the value from the client_config.json file.  

We will run this for both AKS clusters.  

```
kubectl create secret generic "consul-gossip-key" --from-literal="key=$(jq -r .encrypt client_config.json)"  --context $CLUSTER_CLIENT1_CTX
```

```
kubectl create secret generic "consul-gossip-key" --from-literal="key=$(jq -r .encrypt client_config.json)"  --context $CLUSTER_CLIENT2_CTX
```

12. The last secret you need to add is an ACL bootstrap token. You can use the one you set to your CONSUL_HTTP_TOKEN environment variable earlier. Issue the following command to create a Kubernetes secret to store the bootstrap ACL token.  

We will run this for both AKS clusters.  

```
kubectl create secret generic "consul-bootstrap-token" --from-literal="token=${CONSUL_HTTP_TOKEN}" --context $CLUSTER_CLIENT1_CTX
```
```
kubectl create secret generic "consul-bootstrap-token" --from-literal="token=${CONSUL_HTTP_TOKEN}" --context $CLUSTER_CLIENT2_CTX
```

# Create Consul configuration files for each team

13.  Issue the following command to set the HCP Consul cluster DATACENTER environment variable, extracted from the client_config.json file. This env variable will be used in your Consul helm value file.

```
export DATACENTER=$(jq -r .datacenter client_config.json)
```

14. Extract the private server URL from the client_config.json file so that it can be set in the Helm values file as the *externalServers:hosts entry*. 
```
export RETRY_JOIN=$(jq -r --compact-output .retry_join client_config.json)
```

15. Extract the public server URL from the client_config.json file so that it can be set in the Helm values file as the **k8sAuthMethodHost** entry.

```
kubectl config use-context $CLUSTER_CLIENT1_CTX
```

```
export KUBE_API_URL_Team1=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$(kubectl config current-context)\")].cluster.server}")
```

```
kubectl config use-context $CLUSTER_CLIENT2_CTX
```

```
export KUBE_API_URL_Team2=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$(kubectl config current-context)\")].cluster.server}")
```


16. Validate that your environment variables are correct.
```
echo $DATACENTER && \
echo $RETRY_JOIN && \
echo $KUBE_API_URL_Team1 && \
echo $KUBE_API_URL_Team2
```
The output should look similar to the following:
```
consul-cluster-demo
["servers-private-consul-f3239351.7171f9f3.z1.hashicorp.cloud"]
https://dc1-k8s-9f690a3c.hcp.westus2.azmk8s.io:443
https://dc2-k8s-123456dd.hcp.westus2.azmk8s.io:443
```

17. Run the following command to generate the Helm values file for **Team 1**. Notice the environment variables *${DATACENTER}*, *${KUBE_API_URL}*, and *${RETRY_JOIN}* will be used to reflect your specific AKS cluster values.  

Also notice the partition name is team1.

```
cat > config-team1.yaml << EOF
global:
  name: consul
  enabled: false
  datacenter: ${DATACENTER}
  enableConsulNamespaces: true
  adminPartitions:
    enabled: true
    name: "team1"  
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: consul-bootstrap-token
      secretKey: token
  gossipEncryption:
    secretName: consul-gossip-key
    secretKey: key
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: consul-ca-cert
      secretKey: tls.crt
  enableConsulNamespaces: true

externalServers:
  enabled: true
  hosts: ${RETRY_JOIN}
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${KUBE_API_URL_Team1}

client:
  enabled: true
  join: ${RETRY_JOIN}

connectInject:
  enabled: true

controller:
  enabled: true

meshGateway:
  enabled: true
  replicas: 1

EOF
```

18. Run the following command to generate the Helm values file for **Team 2**. Notice the environment variables *${DATACENTER}*, *${KUBE_API_URL}*, and *${RETRY_JOIN}* will be used to reflect your specific AKS cluster values. 

Also notice the partition name is team2.

```
cat > config-team2.yaml << EOF
global:
  name: consul
  enabled: false
  datacenter: ${DATACENTER}
  enableConsulNamespaces: true
  adminPartitions:
    enabled: true
    name: "team2"  
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: consul-bootstrap-token
      secretKey: token
  gossipEncryption:
    secretName: consul-gossip-key
    secretKey: key
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: consul-ca-cert
      secretKey: tls.crt
  enableConsulNamespaces: true

externalServers:
  enabled: true
  hosts: ${RETRY_JOIN}
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${KUBE_API_URL_Team2}

client:
  enabled: true
  join: ${RETRY_JOIN}

connectInject:
  enabled: true

controller:
  enabled: true

meshGateway:
  enabled: true
  replicas: 1

EOF
```  


   
# Deploy Consul for each team 

19. Open a browser and go to the Consul UI using the Consul UI's Public IP address obtained earlier. The public IP address should also be in your environment variable CONSUL_HTTP_ADDR.
```
echo $CONSUL_HTTP_ADDR
```
 
20. On the Consul UI, click on **Admin Partitions** and select **Manage Partitions**.

21. Click **Create** and two new partitions called **team1** and **team2**.  

**Important:** You can change the name of the partition, but it must match the partition names set in your config-team1.yaml and config-team2.yaml file generated in the steps earlier.


22. Now we can deploy the Consul clients into each partitions.  
Add/update HashiCorp to your helm repo
```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

23. Deploy Consul client for team 1.

```
kubectl config use-context $CLUSTER_CLIENT1_CTX
```

```
helm install consul hashicorp/consul --values config-team1.yaml --version "0.43.0" --set global.image=hashicorp/consul-enterprise:1.12.0-ent
```
24. Confirm the Consul client pods are up.

```
kubectl get pod --context $CLUSTER_CLIENT1_CTX
NAME                                           READY   STATUS    RESTARTS   AGE
consul-client-4qrkn                            1/1     Running   0          1m
consul-connect-injector-7c4fd8cbfc-www24       1/1     Running   0          1m
consul-connect-injector-7c4fd8cbfc-zcknn       1/1     Running   0          1m
consul-controller-86c756d855-t5m7d             1/1     Running   0          1m
consul-mesh-gateway-74d77f9859-l4kp9           2/2     Running   0          1m
consul-webhook-cert-manager-6567fdccb7-fdthp   1/1     Running   0          1m
```

25. Deploy Consul client for team 2.

```
kubectl config use-context $CLUSTER_CLIENT2_CTX
```

```
helm install consul hashicorp/consul --values config-team2.yaml --version "0.43.0" --set global.image=hashicorp/consul-enterprise:1.12.0-ent
```

26. Confirm the Consul client pods are up.

```
kubectl get pod --context $CLUSTER_CLIENT2_CTX
NAME                                           READY   STATUS    RESTARTS   AGE
consul-client-fbg67                            1/1     Running   0          1m
consul-connect-injector-ssdf73fbsfk1-23453     1/1     Running   0          1m
consul-connect-injector-ssdf73fbsfk1-zddew     1/1     Running   0          1m
consul-controller-gfdgdfgdr4-e5tgd             1/1     Running   0          1m
consul-mesh-gateway-45gdg45gtr-dfgdd           2/2     Running   0          1m
consul-webhook-cert-manager-cvbfghb564-cbfg54  1/1     Running   0          1m
```
  
  
27. On your Consul UI, the Service and Node tabs should reflect new nodes and a Mesh Gateway service in each partition. 


# Deploy services onto each partition.

Next, we will deploy a simple application that has a frontend and a backend. We will deploy the frontend onto the **team1** partition and the backend onto the **team2** partition. 

We will run through the steps manually so show you exactly how it works.
 
   
1) Deploy frontend app.
```
 kubectl apply -f ../apps/fakeapp/frontend.yaml --context $CLUSTER_CLIENT1_CTX
```
   You should notice the frontend service appear in the Consul UI -> Services window from the team1 partition.

2) Deploy backend app.
```
kubectl apply -f ../apps/fakeapp/backend.yaml --context $CLUSTER_CLIENT2_CTX
```   
   You should notice the backend service appear in the Consul UI -> Services window from the team2 partition.

3) Export services from partition "team2" to parition "team1".
``` 
kubectl apply -f ../apps/fakeapp/export-back.yaml --context $CLUSTER_CLIENT2_CTX
```   
   
4) Export services from partition "team1" to parition "team2".
```   
kubectl apply -f ../apps/fakeapp/export-front.yaml --context $CLUSTER_CLIENT1_CTX   
```   

5) Deploy Proxy-default (or Service-default to specify granular service) to send frontend traffic to Mesh GW.
```
kubectl apply -f ../apps/fakeapp/proxydefault.yaml --context $CLUSTER_CLIENT1_CTX   
```

6) View fakeapp service using EXTERNAL-IP:
```
kubectl get service frontend --context $CLUSTER_CLIENT1_CTX
```
   Open browser and enter the EXTERNAL-IP address and append port 9090 and /ui path to the URL.
   Note: Note: AWS may take a few mins for the EXTERNAL-IP DNS name to resolve. Give it some time.
```   
http://<EXTERNAL-IP>:9090/ui
```   
  You should see two boxes in grey color, depicting that there is connectivity. 
  If the boxes are in red, that means the frontend service is not able to reach the backend service.

