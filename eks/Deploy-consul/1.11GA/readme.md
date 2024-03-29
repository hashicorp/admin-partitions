# Pre-reqs:
- Helm installed (Download: https://github.com/helm/helm/releases).
- Consul Enteprise license: Add license to the install_consul_server.sh script.
  You can request a 30 day trial license here: https://www.hashicorp.com/products/consul/trial 
- 3 EKS Clusters are available. A terraform script is available for you to deploy 3 EKS clusters to your desired AWS regions.
- You are logged onto your AWS acccount

Note: These scripts use environmental variables which only apply to a single terminal session. Therefore run the scripts and commands in these steps 
within the same terminal.


# Pre-Steps: Customize the install scripts with your license and AWS region

Edit the following files with the parameters below: ```install_consul_server.sh```, ```install_consul_client1.sh```, ```install_consul_client2.sh```

- a) Your Enterprice Consul license.  
   
``` 
      export CONSUL_LICENSE=<ADD_YOUR_LICENSE_HERE>
```

You can request a 30 day trial license here: https://www.hashicorp.com/products/consul/trial

- b) Your desired AWS region. Example: 
   
```
      export AWSREGION= eu-north-1
```

# Instructions Steps:

**CONSUL SERVER**




1) Run install_consul_server.sh to deploy Consul Server:
```
source install_consul_server.sh
```
  Note: We're executing the install script using the ```source``` command in order to preserve the environmental variables.

2) Get External-IP (or DNS name) of the Consul server's ```consul-consul-partition-service``` 
```  
  kubectl get services consul-consul-partition-service --context $EKS_CLUSTER_SERVER_CTX
  NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                                                                                                            
  consul-consul-partition-service      LoadBalancer   172.20.138.45    a45c0d48015ed418fbebb1154604f20c-163347652.eu-north-1.elb.amazonaws.com    
```  
  
  Note: On a notepad, copy/paste your output for the External-IP of the "consul-consul-partition-service". We will use in the next couple of steps.


**CONSUL CLIENT 1**


  
3) Get DNS name of EKS API Server of Client 1. Copy/paste the output onto a notepad. We will use this to get the next step.
```   
kubectl config view -o jsonpath="{.clusters[?(@.name=='$EKS_CLUSTER_CLIENT1_CTX')].cluster.server}" | sed 's/https:\/\///'
```
4) Edit helm-client-team1.yaml file:
  
   a) Edit both the ```hosts``` and ```join``` fields to reflect the External-IP (or DNS name) of the consul-consul-partition-service on the Server EKS cluster. 
      You should have noted the External-IP was mentioned in the previous STEP 2.
      
   b) Edit the ```k8sAuthMethodHost``` field to reflect the EKS API server's IP/DNS name of the Client 1 EKS Cluster. 
      You retreived the EKS API server DNS name from STEP 3. 
      
  
  Example inputs for the helm-client-team1.yaml file:
``` 
externalServers:
  enabled: true
  hosts: [ "a45c0d48015ed418fbebb1154604f20c-163347652.eu-north-1.elb.amazonaws.com" ]
  tlsServerName: server.dc1.consul
  k8sAuthMethodHost: "E9122C19C8B28D0DFBC6E0C7DDF16B4D.yl4.eu-north-1.eks.amazonaws.com"
  ...
client:
  enabled: true
  exposeGossipPorts: true
  join: [ "a45c0d48015ed418fbebb1154604f20c-163347652.eu-north-1.elb.amazonaws.com" ]
```

5) Run install_consul_client1.sh script to deploy Consul Client 1:
```
source install_consul_client1.sh
```  
  
  


**CONSUL CLIENT 2**


6) Get DNS name of EKS API Server of Client 2. Make a note of the output. We will use this to get the next step.
```   
kubectl config view -o jsonpath="{.clusters[?(@.name=='$EKS_CLUSTER_CLIENT2_CTX')].cluster.server}" | sed 's/https:\/\///'
```
7) Edit helm-client-team2.yaml file:
  
   a) Edit both the ```hosts``` and ```join``` fields to reflect the External-IP (or DNS name) of the consul-consul-partition-service on the Server EKS cluster. 
      You should have noted the External-IP was mentioned in the previous step 2.
      
   b) Edit the ```k8sAuthMethodHost``` field to reflect the EKS API server's IP/DNS name of the Client 2 EKS Cluster. 
      You retreived the EKS API server DNS name from step 6. 
      
      
  
  Example inputs for the helm-client-team1.yaml file:
``` 
externalServers:
  enabled: true
  hosts: [ "a45c0d48015ed418fbebb1154604f20c-163347652.eu-north-1.elb.amazonaws.com" ]
  tlsServerName: server.dc1.consul
k8sAuthMethodHost: "587856589C8B28D0DFBC6E0C7DDF16B4D.yl4.eu-north-1.eks.amazonaws.com"
  ...
client:
  enabled: true
  exposeGossipPorts: true
  join: [ "a45c0d48015ed418fbebb1154604f20c-163347652.eu-north-1.elb.amazonaws.com" ]
```

8) Run install_consul_client2.sh to deploy Consul Client 2
```
source install_consul_client2.sh
```      
Consul will now be install with two separate Kubernetes Clusters belonging to two separate Consul partitions (team1 and team2) 
Teams/tenants can deploy their services in their respective K8s clusters and will be completely isolated from teams and services
in other partitions.
      
      


# VIEW UI



To view the Consul UI with a browser, use the EXTERNAL-IP of the consul ui service. 
Note: TLS is enabled in this example, therefore use https:// with port 443.
```
kubectl get services consul-consul-ui --context $EKS_CLUSTER_SERVER_CTX
NAME               TYPE           CLUSTER-IP       EXTERNAL-IP                                                                PORT(S)         
consul-consul-ui   LoadBalancer   172.20.183.226   a4f396d083ebe43559e2e29582ea3b35-1404433695.eu-north-1.elb.amazonaws.com   443:32563/TCP  
```
For demo purposes, you can use the boostrap ACL token to log ontn UI. Token can be retrieve with:
```
kubectl get secrets/consul-consul-bootstrap-acl-token --template='{{.data.token | base64decode }}' --context $EKS_CLUSTER_SERVER_CTX
```
In the UI, notice you can toggle between partitions using the Admin Partition box in the upper left side.



# CROSS PARTITION COMMUNICATION



This is an example showing a simple app that has a frontend service in the "team1" partition that connects to a backend service in  thw "team1" partition.
We will run through the steps manually so show you exactly how it works.
 
   
1) Deploy frontend app.
```
kubectl apply -f apps/fakeapp/frontend.yaml --context $EKS_CLUSTER_CLIENT1_CTX 
```
   You should notice the frontend service appear in the UI -> Services window from the team1 partition.

2) Deploy backend app.
```
kubectl apply -f apps/fakeapp/backend.yaml --context $EKS_CLUSTER_CLIENT2_CTX
```   
   You should notice the backend service appear in the UI -> Services window from the team2 partition.

3) Export services from partition "team2" to parition "team1".
``` 
kubectl apply -f apps/fakeapp/export-back.yaml --context $EKS_CLUSTER_CLIENT2_CTX
```   
   
4) Export services from partition "team1" to parition "team2".
```   
kubectl apply -f apps/fakeapp/export-front.yaml --context $EKS_CLUSTER_CLIENT1_CTX   
```   


5) Deploy Proxy-default (or Service-default to specify granular service) to send frontend traffic to Mesh GW.
```
kubectl apply -f proxydefault.yaml --context $EKS_CLUSTER_CLIENT1_CTX   
```


6) View fakeapp service using EXTERNAL-IP:
```
kubectl get service frontend --context $EKS_CLUSTER_CLIENT1_CTX
```
   Open browser and enter the EXTERNAL-IP address and append port 9090 and /ui path to the URL.
   Note: Note: AWS may take a few mins for the EXTERNAL-IP DNS name to resolve. Give it some time.
```   
http://<EXTERNAL-IP>:9090/ui
```   
  You should see two boxes in grey color, depicting that there is connectivity. 
  If the boxes are in red, that means the frontend service is not able to reach the backend service.
