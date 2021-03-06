#!/bin/bash
set -euo pipefail


function findVM
{
  BASEREULT=$(az vm list-ip-addresses --subscription $1)
  RES_PRIVATE=$(echo $BASEREULT | jq -r --arg IP "$2" 'map(select(.virtualMachine.network.privateIpAddresses[] | select (.==$IP))) | .[] | .virtualMachine.name +  "," + .virtualMachine.resourceGroup')
  RES_PUBLIC=$(echo $BASEREULT | jq -r --arg IP "$2" 'map(select(.virtualMachine.network.publicIpAddresses[] | select(.ipAddress==$IP))) | .[] | .virtualMachine.name +  "," + .virtualMachine.resourceGroup')

  if [[ -n $RES_PRIVATE ]];
  then
    read -r VMName RG <<< $(awk -F "[,]" '{print $1, $2}' <<< "${RES_PRIVATE}")
    SUBACCOUNTNAME=$(az account list --all | jq -r --arg ACCOUNTID "$1" '.[] | select (.id==$ACCOUNTID) | .name')
    echo "Search IP: ${ipAddress}"
    echo "IP type: Private IP"
    echo "SubAccount: ${SUBACCOUNTNAME}"
    echo "VirtualMachine Name: ${VMName}"
    echo "Resource Group: ${RG}"
    exit 1
  fi
  if [[ -n $RES_PUBLIC ]];
  then
    read -r VMName RG <<< $(awk -F "[,]" '{print $1, $2}' <<< "${RES_PUBLIC}")
    SUBACCOUNTNAME=$(az account list --all | jq -r --arg ACCOUNTID "$1" '.[] | select (.id==$ACCOUNTID) | .name')
    echo "Search IP: ${ipAddress}"
    echo "IP type: Public IP"
    echo "SubAccount: ${SUBACCOUNTNAME}"
    echo "VirtualMachine Name: ${VMName}"
    echo "Resource Group: ${RG}"
    exit 1
  fi
} 


usage() { echo "Usage: $0 -i <PIP>" 1>&2; exit 1; }

declare ipAddress=""
# Initialize parameters specified from command line
while getopts "i:" arg; do
  case "${arg}" in
    i)
      ipAddress=${OPTARG}
      ;;
    esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$ipAddress" ]]; then
  echo "You need to provide your ipAddress"
  echo "Enter the private IP"
  read ipAddress
  [[ "${ipAddress:?}" ]]
fi

# verify if the az cli has login.
az account show 1> /dev/null

if [ $? != 0 ];
then
  az login
fi

declare -a SUBACCOUNTS
#SUBACCOUNTS=$(az account list --all | jq -r '.[] | .name' | tr '\n' ',' | sed 's/,$//')
SUBACCOUNTS=$(az account list --all | jq -r '.[] | .id')

for SUBACCOUNT in ${SUBACCOUNTS};
do
  findVM $SUBACCOUNT $ipAddress
done
