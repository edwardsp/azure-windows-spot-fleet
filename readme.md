
```
az group create --name paul-windows-spot-fleet --location westeurope
az deployment group create --resource-group paul-windows-spot-fleet --template-file infra.bicep
az deployment group create --resource-group paul-windows-spot-fleet --template-file spotfleet.bicep
```