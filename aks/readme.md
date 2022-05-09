# Here are the high level steps to deploy Consul with Admin Partitions onto AKS.


# Pre-reqs

1) Clone this repo: 

   git clone 

2) Deploy 3 AKS clusters in your Azure envronments. Make sure when you create your AKS clusters that you are selecting the Azure CNI (instead of Kubenet)
    
    
    
# Deploy Consul Server

1) Set you Consul Enterprise license as an environmental variable. 

``` 
export CONSUL_LICENSE=<ADD_YOUR_LICENSE_HERE>
```

You can request a 30 day trial license here: https://www.hashicorp.com/products/consul/trial

2) Set environmental variables for your server and client kubernetes contexts
```
export EKS_CLUSTER_SERVER_CTX=<YOUR_K8s_CONTEXT__FOR_CONSUL_SERVER>
export EKS_CLUSTER_CLIENT1_CTX=<YOUR_K8s_CONTEXT__FOR_CONSUL_CLIENT1>
export EKS_CLUSTER_CLIENT1_CTX=<YOUR_K8s_CONTEXT__FOR_CONSUL_CLIENT2>
```

3) Add/Update consul repo

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update 
```

4) Set Consul context to point to the K8s cluster for the Consul server.

```
kubectl config use-context $EKS_CLUSTER_SERVER_CTX
```

5) Add Consul Ent license as a K8s secret

```
kubectl create secret generic license --from-literal=key=$CONSUL_LICENSE
```

6) Deploy Consul server

```
helm install consul hashicorp/consul -f helm-server.yaml --wait --debug
```

When complete, example deplpoyment:

```
kubectl get pods --context $EKS_CLUSTER_SERVER_CTX
NAME                                                 READY   STATUS    RESTARTS   AGE
consul-consul-client-7dwsh                           1/1     Running   0          99m
consul-consul-connect-injector-74687f4679-8jbhm      1/1     Running   0          99m
consul-consul-connect-injector-74687f4679-tlgdn      1/1     Running   0          99m
consul-consul-controller-64d7fd44d-dkvnc             1/1     Running   0          99m
consul-consul-server-0                               1/1     Running   0          99m
consul-consul-webhook-cert-manager-9d4f5fbd9-7k45t   1/1     Running   0          99m
```

    
# Deploy Consul Client 1

7) Retreieve the External-IP of the Consul server's consul-consul-partition-service and send the output into an environmental variable. We will use this variable when we configure the Consul Client yaml file.


```
export CONSUL_PARTITION_SVC=$(kubectl get services consul-consul-partition --context $EKS_CLUSTER_SERVER_CTX -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

8) Retreieve the Kubernetes API server from theKubernetes Client Cluster and send the output into an environmental variable. We will use this variable when we configure the Consul Client yaml file.

```
export K8S_AUTH_HOST=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='$EKS_CLUSTER_CLIENT1_CTX')].cluster.server}" | sed 's/https:\/\///' | sed 's/:443//')
```
9) Generate the Consul Client cluster yaml file.

Note: The partition name will be ```team1```. If you wish to use a different paftition name, you can change the ```adminPartitions.name``` parameter below.

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
  k8sAuthMethodHost: ${K8S_AUTH_HOST}
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

#meshGateway:
#  enabled: true

dns:
  enabled: true
  enableRedirection: true 
EOF
```

10) Copy tls cert/keys and partition acl tokens from Consul server cluster to the client cluster. This is needed if tls and acls are enabled.

```
kubectl get secret consul-consul-ca-cert --context $EKS_CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $EKS_CLUSTER_CLIENT1_CTX -f -
kubectl get secret consul-consul-ca-key --context $EKS_CLUSTER_SERVER_CTX -o yaml | kubectl apply --context $EKS_CLUSTER_CLIENT1_CTX -f -
kubectl get secret consul-consul-partitions-acl-token --context $EKS_CLUSTER_SERVER_CTX -o json | kubectl apply --context $EKS_CLUSTER_CLIENT1_CTX -f -
```

11) Set Consul context to point to the K8s cluster for the Consul server.
```
kubectl config use-context $EKS_CLUSTER_CLIENT1_CTX
```
12) Add Consul Ent license as a K8s secret
```
kubectl create secret generic license --from-literal=key=$CONSUL_LICENSE
```
13) Deploy Consul

helm install consul hashicorp/consul -f helm-client-team1.yaml --wait --debug


Example output of successful deployment:
```
kubectl get pod --context $EKS_CLUSTER_CLIENT1_CTX
NAME                                                 READY   STATUS    RESTARTS   AGE
consul-consul-client-2nl76                           1/1     Running   0          89m
consul-consul-connect-injector-c855cdc-gmg6l         1/1     Running   0          89m
consul-consul-connect-injector-c855cdc-kwqlg         1/1     Running   0          89m
consul-consul-controller-85b4954894-4qmrs            1/1     Running   0          89m
consul-consul-webhook-cert-manager-9d4f5fbd9-dvkpb   1/1     Running   0          89m
```


# Deploy Consul Client 2

7) Retreieve the External-IP of the Consul server's consul-consul-partition-service and send the output into an environmental variable. We will use this variable when we configure the Consul Client yaml file.


```
export CONSUL_PARTITION_SVC=$(kubectl get services consul-consul-partition --context $EKS_CLUSTER_SERVER_CTX -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

8) Retreieve the Kubernetes API server from theKubernetes Client Cluster and send the output into an environmental variable. We will use this variable when we configure the Consul Client yaml file.

```
export K8S_AUTH_HOST=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='$EKS_CLUSTER_CLIENT1_CTX')].cluster.server}" | sed 's/https:\/\///' | sed 's/:443//')
```
9) Generate the Consul Client cluster yaml file.

Note: The partition name will be ```team1```. If you wish to use a different paftition name, you can change the ```adminPartitions.name``` parameter below.
