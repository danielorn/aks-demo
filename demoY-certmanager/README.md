# Install cert manager

helm repo add jetstack https://charts.jetstack.io --force-update

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml

kubectl create ns cert-manager

helm install cert-manager --namespace cert-manager --version v1.17.1 jetstack/cert-manager


# Create MI for cert manager and assign role to public dns zone

$CLUSTERNAME = "dev24-aks"
$CLUSTERRG = "dev24-aks-rg"
$RGNAME = "dev24-aks-rg"
$DOMAIN_NAME = "az.dev24.se"
$DNSRG = "rg-public-dns"
$DNSSUBSCRIPTION = "d54725e5-5619-4f5e-9b61-8a513f17e43b"

az identity create --name umi-cert-manager --resource-group $RGNAME --location swedencentral

$issuerUrl = az aks show --name $CLUSTERNAME -g $CLUSTERRG  --query "oidcIssuerProfile.issuerUrl" --output tsv
$clientId = az identity show --name umi-cert-manager --resource-group $RGNAME --query 'clientId' -o tsv

az identity federated-credential create --name fc-cert-manager --identity-name umi-cert-manager -g $RGNAME --issuer $issuerUrl --subject system:serviceaccount:cert-manager:cert-manager --audiences api://AzureADTokenExchange

az role assignment create --role "DNS Zone Contributor" --assignee $clientId  --scope $(az network dns zone show --name $DOMAIN_NAME --resource-group $DNSRG --subscription $DNSSUBSCRIPTION -o tsv --query id)

# Deploy issuer

kubectl apply -f 