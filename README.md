# Azure-tools
The azure bash tools for sharing

## Requirement
Azure Cli
[Official installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)


## Tool list
### findVmByPrivateIp.sh
There is no feature in Azure console to find the Virtual Machine by IP address.

How to use:
```bash
./findVmByPrivateIp.sh -i [IP Address]

```
return data if data has been found:
```bash
Search IP: [IP Address]  
IP type: Public IP/Private IP
SubAccount: [related subaccount]
VirtualMachine Name: [name of your VM]
Resource Group: [name of your resource group]
```

Something needs to trigger
