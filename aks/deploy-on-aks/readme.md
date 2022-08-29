# Steps to deploy Consul with Admin Partitions onto AKS clusters.

This repo will guide you through deploying Consul onto three Kubernetes clusters to demonstrate Consul's multi-tenancy feature, Administrative Partitions. You will deploy the Consul server in one K8s cluster and two Consul clients on the other two K8s clusters. Each Consul client will represent a different tenant.

# Pre-reqs

1) Clone this repo and navigate to the ```admin-partitions/aks/deploy-on-aks``` directory.
```
   git clone https://github.com/hashicorp/admin-partitions.git
```

2) Deploy 3 AKS clusters in your Azure envronments. Make sure when you create your AKS clusters that you are selecting the Azure CNI (instead of Kubenet)
    
3) A Consul Enterprise license. You can request a 30 day trial license here: https://www.hashicorp.com/products/consul/trial
   
    
# Deploy Consul Server

1) Set you Consul Enterprise license as an environmental variable. 

``` 
export CONSUL_LICENSE=<ADD_YOUR_LICENSE_HERE>
```

You can request a 30 day trial license here: https://www.hashicorp.com/products/consul/trial

2) Set environmental variables for your 3 clusters:
```
export CLUSTER_SERVER_CTX=<YOUR_K8s_CONTEXT_FOR_CONSUL_SERVER>
export CLUSTER_CLIENT1_CTX=<YOUR_K8s_CONTEXT_FOR_CONSUL_CLIENT1>
export CLUSTER_CLIENT2_CTX=<YOUR_K8s_CONTEXT_FOR_CONSUL_CLIENT2>
```

3) Add/Update consul repo

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update 
```

4) Set the Kubernetes context to point to the K8s cluster of the Consul server.

```
kubectl config use-context $CLUSTER_SERVER_CTX
```

5) Add Consul Ent license as a K8s secret

```
kubectl create secret generic license --from-literal=key=$CONSUL_LICENSE
```

6) Deploy Consul server

```
helm install consul hashicorp/consul -f helm-server.yaml --version=0.43.0 --wait --debug
```

When complete, example deplpoyment:

```
kubectl get pods --context $CLUSTER_SERVER_CTX
NAME                                                 READY   STATUS    RESTARTS   AGE
consul-consul-client-49m6n                           1/1     Running   0          99m
consul-consul-client-7dwsh                           1/1     Running   0          99m
consul-consul-connect-injector-74687f4679-8jbhm      1/1     Running   0          99m
consul-consul-connect-injector-74687f4679-tlgdn      1/1     Running   0          99m
consul-consul-controller-64d7fd44d-dkvnc             1/1     Running   0          99m
consul-consul-server-0                               1/1     Running   0          99m
consul-consul-webhook-cert-manager-9d4f5fbd9-7k45t   1/1     Running   0          99m
```

    
# Deploy Consul Client 1

7) Retrieve the External-IP of the Consul server's consul-consul-partition service and send the output into an environmental variable. We will use this variable when we configure the Consul Client yaml file.


```
export CONSUL_PARTITION_SVC=$(kubectl get services consul-consul-partition --context $CLUSTER_SERVER_CTX -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

8) Retrieve the Kubernetes API server from the Kubernetes **Client 1** cluster and send the output into an environmental variable. We will use this variable when we configure the Consul client yaml file.

```
export K8S_AUTH_HOST_CLIENT1=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='$CLUSTER_CLIENT1_CTX')].cluster.server}" | sed 's/https:\/\///' | sed 's/:443//')
```
9) Generate the Consul client 1 cluster yaml file.

Note: The partition name will be ```team1```. If you wish to use a different partition name, you can change the ```global.adminPartitions.name``` parameter below.

```
cat <<EOF > helm-client-team1.yaml
global:
  enabled: false
  enableConsulNamespaces: true
  image: hashicorp/consul-enterprise:1.12.0-ent
  adminPartitions:
    enabled: true
    name: "team1"

  enterpriseLicense:
    secretName: license
    secretKey: key

  tls:
    enabled: true
    caCert:
      secretName: consul-consul-ca-cert
      secretKey: tls.crt
    caKey:
      secretName: consul-consul-ca-key
      secretKey: tls.key

  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: consul-consul-partitions-acl-token
      secretKey: token

externalServers:
  enabled: true
  hosts: [ "${CONSUL_PARTITION_SVC}" ] 
  tlsServerName: server.dc1.consul
  k8sAuthMethodHost: ${K8S_AUTH_HOST_CLIENT1}
client:
  enabled: true
  exposeGossipPorts: true
  join: [ "${CONSUL_PARTITION_SVC}" ]
connectInject:
  enabled: true
  consulNamespaces:
    mirroringK8S: true
  envoyExtraArgs: --log-level trace

controller:
  enabled: true

meshGateway:
  enabled: true

dns:
  enabled: true
  enableRedirection: true 
EOF
```

10) Copy tls cert/keys and partition acl tokens from Consul server cluster to the client cluster. This is needed if tls and acls are enabled.

```
kubectl get secret consul-consul-ca-cert --context $CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $CLUSTER_CLIENT1_CTX -f -
kubectl get secret consul-consul-ca-key --context $CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $CLUSTER_CLIENT1_CTX -f -
kubectl get secret consul-consul-partitions-acl-token --context $CLUSTER_SERVER_CTX -o json | kubectl apply --context $CLUSTER_CLIENT1_CTX -f -
```

11) Set the Kubernetes context to point to the K8s cluster of the **first** Consul client.
```
kubectl config use-context $CLUSTER_CLIENT1_CTX
```
12) Add Consul Ent license as a K8s secret
```
kubectl create secret generic license --from-literal=key=$CONSUL_LICENSE
```
13) Deploy Consul
```
helm install consul hashicorp/consul -f helm-client-team1.yaml --version=0.43.0 --wait --debug
```

Example output of successful deployment:
```
kubectl get pod --context $CLUSTER_CLIENT1_CTX
NAME                                                 READY   STATUS    RESTARTS   AGE
consul-consul-client-2nl76                           1/1     Running   0          89m
consul-consul-connect-injector-c855cdc-gmg6l         1/1     Running   0          89m
consul-consul-connect-injector-c855cdc-kwqlg         1/1     Running   0          89m
consul-consul-controller-85b4954894-4qmrs            1/1     Running   0          89m
consul-consul-webhook-cert-manager-9d4f5fbd9-dvkpb   1/1     Running   0          89m
```


# Deploy Consul Client 2

14) Retrieve the Kubernetes API server from the Kubernetes **Client 2** cluster and send the output into an environmental variable. We will use this variable when we configure the Consul client yaml file.

```
export K8S_AUTH_HOST_CLIENT2=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='$CLUSTER_CLIENT2_CTX')].cluster.server}" | sed 's/https:\/\///' | sed 's/:443//')
```
15) Generate the Consul client 2 cluster yaml file.

Note: The partition name will be ```team2```. If you wish to use a different paftition name, you can change the ```adminPartitions.name``` parameter below.

```
cat <<EOF > helm-client-team2.yaml
global:
  enabled: false
  enableConsulNamespaces: true
  image: hashicorp/consul-enterprise:1.12.0-ent
  adminPartitions:
    enabled: true
    name: "team2"

  enterpriseLicense:
    secretName: license
    secretKey: key

  tls:
    enabled: true
    caCert:
      secretName: consul-consul-ca-cert
      secretKey: tls.crt
    caKey:
      secretName: consul-consul-ca-key
      secretKey: tls.key

  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: consul-consul-partitions-acl-token
      secretKey: token

externalServers:
  enabled: true
  hosts: [ "${CONSUL_PARTITION_SVC}" ] 
  tlsServerName: server.dc1.consul
  k8sAuthMethodHost: ${K8S_AUTH_HOST_CLIENT2}
client:
  enabled: true
  exposeGossipPorts: true
  join: [ "${CONSUL_PARTITION_SVC}" ]
connectInject:
  enabled: true
  consulNamespaces:
    mirroringK8S: true
  envoyExtraArgs: --log-level trace

controller:
  enabled: true

meshGateway:
  enabled: true

dns:
  enabled: true
  enableRedirection: true 
EOF
```

16) Copy tls cert/keys and partition acl tokens from Consul server cluster to the client cluster. This is needed if tls and acls are enabled.

```
kubectl get secret consul-consul-ca-cert --context $CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $CLUSTER_CLIENT2_CTX -f -
kubectl get secret consul-consul-ca-key --context $CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $CLUSTER_CLIENT2_CTX -f -
kubectl get secret consul-consul-partitions-acl-token --context $CLUSTER_SERVER_CTX -o json | kubectl apply --context $CLUSTER_CLIENT2_CTX -f -
```


17) Set the Kubernetes context to point to the K8s cluster of the **second** Consul client.

```
kubectl config use-context $CLUSTER_CLIENT2_CTX
```

18) Add Consul Ent license as a K8s secret
```
kubectl create secret generic license --from-literal=key=$CONSUL_LICENSE
```

19) Deploy Consul
```
helm install consul hashicorp/consul -f helm-client-team2.yaml --version=0.43.0 --wait --debug
```

Example output of successful deployment:
```
kubectl get pod --context $CLUSTER_CLIENT2_CTX
NAME                                                 READY   STATUS    RESTARTS   AGE
backend-7fc9d878cd-k8f2j                             2/2     Running   0          74m
consul-consul-client-pbwlz                           1/1     Running   0          88m
consul-consul-connect-injector-85fb9dcccf-8dt59      1/1     Running   0          88m
consul-consul-connect-injector-85fb9dcccf-9gvt4      1/1     Running   0          88m
consul-consul-controller-75446bcc64-4wnmg            1/1     Running   √0          88m
consul-consul-webhook-cert-manager-9d4f5fbd9-8z6jc   1/1     Running   0          88m
vanphan@vanphan-F664JHFD6G 1.11GA % 
```


# View UI

20) To view the Consul UI with a browser, use the EXTERNAL-IP of the consul ui service. 

Note: TLS is enabled in this example, therefore use https:// with port 443.

```
kubectl get svc consul-consul-ui --context $CLUSTER_SERVER_CTX -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Consul UI Log-in**

For demo purposes, you can use the boostrap ACL token to log ontn UI. Token can be retrieve with:
```
kubectl get secrets/consul-consul-bootstrap-acl-token --template='{{.data.token | base64decode }}' --context $CLUSTER_SERVER_CTX
```

Notice that additional partitions are now visible in the Admin Partition pull-down menu.

![alt text](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-05-10%20at%208.52.17%20AM.png)

# CROSS PARTITION COMMUNICATION


This is an example showing a simple app that has a frontend service in the "team1" partition that connects to a backend service in thw "team1" partition. We will run through the steps manually so show you exactly how it works.

21) Deploy frontend app.
```
kubectl apply -f ../apps/fakeapp/frontend.yaml --context $CLUSTER_CLIENT1_CTX 
```

22) Deploy backend app.
```
kubectl apply -f ../apps/fakeapp/backend.yaml --context $CLUSTER_CLIENT2_CTX
```
You should notice the backend service appear in the UI -> Services window from the team2 partition.

23) Export services from partition "team2" to parition "team1".
```
kubectl apply -f ../apps/fakeapp/export-back.yaml --context $CLUSTER_CLIENT2_CTX
```

24) Run command below.
  
```export services from partition "team1" to parition "team2".
kubectl apply -f ../apps/fakeapp/export-front.yaml --context $CLUSTER_CLIENT1_CTX   
```

25) Deploy Proxy-default (or Service-default to specify granular service) to send frontend traffic to Mesh GW.
```
kubectl apply -f ../apps/fakeapp/proxydefault.yaml --context $CLUSTER_CLIENT1_CTX   
```


26) View fakeapp service using EXTERNAL-IP:
```
kubectl get service frontend --context $CLUSTER_CLIENT1_CTX
```

Open browser and enter the EXTERNAL-IP address and append port 9090 and /ui path to the URL. Note: Note: AWS may take a few mins for the EXTERNAL-IP DNS name to resolve. Give it some time.

```http://<EXTERNAL-IP>:9090/ui```

   You should see two boxes in white color, depicting that there is connectivity. If the boxes are red, that means the frontend service is not able to reach the backend service.
   
![alt text](https://github.com/hashicorp/admin-partitions/blob/main/images/Screen%20Shot%202022-05-10%20at%208.40.28%20AM.png)
