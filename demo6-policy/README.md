# Introdukction

**Overview**
https://learn.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes

**Built in policy reference**
https://learn.microsoft.com/en-us/azure/aks/policy-reference


# Labs

## 1. Update settings of policies in Microsoft Cloud Security Benchmark
When enabling [Microsoft Cloud Security Benchmark](https://learn.microsoft.com/en-us/security/benchmark/azure/overview) in Defender for cloud a number of Policy assignments related to Kubernetes resources are done as part of the ASC Default initiative.

The settings for those policies can be tailored further to meet your organizational requirements, in this lab we will have a look at the policy [Kubernetes cluster containers should only use allowed images](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Ffebd0533-8e55-448f-b837-bd0e06f16469)

You can list all constraint templates in the cluster using the following command

```sh
kubectl get constrainttemplate
```

To list all constraints defined based on the constraintTemplate called `k8sazurev2containerallowedimages`, which restricts what images are allowed in the cluster, run the following command

```sh
kubectl get k8sazurev2containerallowedimages -o=custom-columns='NAME:metadata.name,imageRegex:spec.parameters.imageRegex,ENFORCEMENT:spec.enforcementAction'
```

Note that default regex defined (`^(.+){0}$`), which matches nothing, and that the enforcement is `dry-run`, which means violations are logged (and reported in Azure policy) but not enforced

**To change the policy assignment settings:**
1. Navigate to
    - Defender for cloud
    - Environment Settings
    - (Your Subscription)
    - Security Policies
2. Select `Manage` from the three dots `...`
3. Locate the assignment called `Container images should be deployed from trusted registries only`
4. Update the settings
    - Allowed registry or registries regex: `^NAMEOFMYACR\.azurecr\.io\/.+$`
    - Policy effect: `Deny`


The Azure policy addon refreshes definitions from Azure policy every 15 minutes, so it can take a few minutes for the change to take effect in the cluster. Monitor the constraints until the new regex shows up

```sh
kubectl get k8sazurev2containerallowedimages -o=custom-columns='NAME:metadata.name,imageRegex:spec.parameters.imageRegex,ENFORCEMENT:spec.enforcementAction'
```

## 2. Assign built in policy (Require annotations)
There is a built in policy that can enforce certain annotations to be present on kubernetes objects (for example pods): [Kubernetes resources should have required annotations
](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F9a5f4e39-e427-4d5d-ae73-93db00328bec)

Assign the policy above to the resource group where your AKS cluster is deployed using the following parameters (the rest can be left as default):

- In `annotations` parameter put:
    ```json
    {"annotations":[{"key": "owner", "allowedRegex": "^([\\w\\.]*)@mycompany\\.tld$"}]}
    ```
- In `Effect` put
    ```
    Deny
    ```
- In `Resource kind` put
    ```
    Pod
    ```

Wait until the constraint template and constraint is deployed to the cluster
```sh
kubectl get  k8sazurev1requiredannotations
```

Test to deploy an invalid pod (one that does not specify a valid owner)
```sh
kubectl apply -f .\RequireAnnotations\violation.yaml
```

Test to deploy a valid pod (one that does specify a valid owner)
```sh
kubectl apply -f .\RequireAnnotations\success.yaml
```

# 3. Create custom policy (Require resource requests)

It is also possible to create a custom constraint template and wrap that in a an Azure policy and assign it.

The example in [RequireAnnotations/](RequireAnnotations/) wraps the gatekeeper community policy [k8scontainerrequests](https://open-policy-agent.github.io/gatekeeper-library/website/validation/containerrequests) in an Azure policy and assigns it to the current subscription using bicep.

```sh
az deployment sub create --name policy --template-file .\RequireContainerResourceRequests\main.bicep --location swedencentral
```

Wait until the constraint template and constraint is deployed to the cluster
```sh
kubectl get  k8scontainerrequests
```

Test to deploy an invalid pod (one that does not specify resource requests)
```sh
kubectl apply -f .\RequireContainerResourceRequests\violation.yaml
```

Test to deploy a valid pod (one that does specify resource requests)
```sh
kubectl apply -f .\RequireContainerResourceRequests\success.yaml
```