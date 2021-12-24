param naming object
param location string = resourceGroup().location
param tags object

@secure()
param logViewerUsername string

@secure()
param logViewerPassword string

@allowed([
  'standard'
  'premium'
])
@description('Azure Key Vault SKU')
param keyVaultSku string = 'premium'

var resourceNames = {
  functionApp: naming.functionApp.name
  logStorageAccount: naming.storageAccount.nameUnique
  keyVault: naming.keyVault.nameUnique
}

var secretNames = {
  logViewerUsername: 'logViewerUsername'
  logViewerPassword: 'logViewerPassword'
  logStorageConnectionString: 'logStorageConnectionString'
}

var azureFunctionPlanSkuName = 'Y1'

// Function Application (with respected Application Insights and Storage Account)
// with the respective configuration, and deployment of the application
module funcApp './modules/functionApp.module.bicep' = {
  name: 'funcApp'
  params: {
    location: location
    name: resourceNames.functionApp
    managedIdentity: true
    tags: tags
    skuName: azureFunctionPlanSkuName
    funcAppSettings: [
      {
        name: 'LogViewerUsername'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.logViewerUsername})'
      }
      {
        name: 'LogViewerPassword'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.logViewerPassword})'
      }
      {
        name: 'LogStorageConnectionString'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.logStorageConnectionString})'
      }
    ]
  }
}


module keyVault 'modules/keyvault.module.bicep' = {
  name: 'keyVault'
  params: {
    name: resourceNames.keyVault
    location: location
    skuName: keyVaultSku
    tags: tags
    accessPolicies: [
      {
        tenantId: funcApp.outputs.identity.tenantId
        objectId: funcApp.outputs.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
    secrets: [
      {
        name: secretNames.logViewerUsername
        value: logViewerUsername
      }
      {
        name: secretNames.logViewerPassword
        value: logViewerPassword
      }
      {
        name: secretNames.logStorageConnectionString
        value: auditLogStorage.outputs.connectionString
      }
    ]
  }
}


// Deploying a module, passing in the necessary naming parameters (storage account name should be also globally unique)
module auditLogStorage 'modules/storage.module.bicep' = {
  name: 'StorageAccountDeployment'
  params: {
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    name: resourceNames.logStorageAccount
    tags: tags
  }
}

output storageAccountName string = auditLogStorage.outputs.name
