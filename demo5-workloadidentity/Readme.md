# Worload identity



## Create RG

```
az group create -n $RGNAME -l swedencentral
```

## Create a user assigned managed identity

```
az identity create --name umi-app --resource-group $RGNAME --location swedencentral
```

## Assign roles

```
az role assignment create --role "Reader" --assignee $CLIENTID --scope /subscriptions/$SUBSCRIPTIONID
```

## Create federated credential


**Fetch the issuer Url**
``` 
az aks show --name $CLUSTERNAME -g $CLUSTERRG $ --query "oidcIssuerProfile.issuerUrl" --output tsv 
```

**Create a federated credential for a sevrice account called `svc-app` in `$NAMESPACE`**
```sh
az identity federated-credential create --name fc-app --identity-name umi-app -g $RGNAME --issuer [Cluster Issuer URL] --subject system:serviceaccount:$NAMESPACE:svc-app --audiences api://AzureADTokenExchange
```


## Deploy service account in AKS

**Fetch Details about the Managed identity**
```sh
az identity show --name umi-[prefix] -g rg-[prefix] --query "{clientId:clientId,tenantId:tenantId}" --output tsv
```

**Edit `svc-app.yaml` and insert the clientId and tenantId**

**Deploy the service account**
```sh
kubectl apply -f svc-app.yaml
```

## Deploy a pod that uses t he service account

```sh
kubectl apply -f deployment.yaml
```

## Exec into the pod and try the credentials

**Exec into the pod**
```sh
kubectl exec -it $PODNAME -- bash
```

**Inside pod: Check injected Azure environment variables**
```sh
env | grep AZURE_
```

**Inside pod: View the injected Token (The token can be decoded using for example jwt.io)**
```sh
cat $AZURE_FEDERATED_TOKEN_FILE
```

**Inside pod: Authenticate using Azure cli**
```sh
az login --federated-token "$(cat  $AZURE_FEDERATED_TOKEN_FILE)" --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID
```

**Inside pod: List all resource groups**
```sh
az group list --query [].name
```

**Inside pod: Attempt to create a resource group (fails due to lack of permissions)**
```sh
az group create --name test --location swedencentral
```