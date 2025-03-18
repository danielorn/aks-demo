targetScope = 'subscription'
param location string = 'swedencentral'
param memoryLimit string = '100Gi'
param cpuLimit string = '100' // 100 cores
param namespaces array = []
param excludedNamespaces array = [
  'kube-system'
  'gatekeeper-system'
  'azure-arc'
  'azure-extensions-usage-system'
]
param effect string = 'deny'
param labelSelector object = {}
param source string = 'Original'

var policyName = 'RequireContainerResourceRequests'
var constraintTemplate = base64(loadTextContent('constraintTemplate.yaml'))
var policyDefinition = json(replace(loadTextContent('policy.json'), '{{CONSTRAINT}}', constraintTemplate))

resource policy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: guid(policyName)
  properties: policyDefinition
}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: '${policyName}Assignment'
  location: location
  properties: {
    policyDefinitionId: policy.id
    parameters: {
      memoryLimit: {
        value: memoryLimit
      }
      cpuLimit: {
        value: cpuLimit
      }
      namespaces: {
        value: namespaces
      }
      excludedNamespaces: {
        value: excludedNamespaces
      }
      effect: {
        value: effect
      }
      labelSelector: {
        value: labelSelector
      }
      source: {
        value: source
      }
    }
  }
}
