# Demo 1 Network policies

## Install kubectl

```sh
az aks install-cli
```

## Log into kubernetes cluster

```sh 
az aks get-credentials --resource-group $RG --name $CLUSTER --overwrite-existing
```

## Create namespace

```sh 
kubectl create ns $NAMESPACE
```

## Set your namespace as default for kubectl operations

```sh 
kubectl config set-context --current --namespace=$NAMESPACE
```

## Deploy nginx deployments

Replace the placeholder `{{NAME}}` with your name in `nginx1.yaml` and `nginx2.yaml`

```sh
kubectl apply -f demo1-networkpolicies/nginx1.yaml
kubectl apply -f demo1-networkpolicies/nginx2.yaml
```

## Kubectl port forward

```sh 
kubectl port-forward service/nginx1-service 8000:80
```

Visit http://localhost:8000 in your browser

## Launch busyboxpod to connect to nginx

```sh
kubectl run -it busybox --image=busybox --rm --restart=Never
```

Use the `wget` command inside th pods to call the different nginx pods

```
wget -O - nginx1-service
wget -O - nginx2-service
```

Also test to query someone elses namespace

```sh
wget -O - nginx1-service.$NS.svc.cluster.lcoal
```

## Clean up

```sh
k delete -f demo1-networkpolicies/
```
