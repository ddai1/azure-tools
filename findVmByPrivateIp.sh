#!/bin/bash
set -euo pipefail


function findVM
{
  INIRESULT=$(az network nic list --subscription $1| jq -r --arg PIP "$2" '.[]| select (.ipConfigurations[0].privateIpAddress==$PIP) | .ipConfigurations[0].privateIpAddress + "@" + .virtualMachine.id + "@" + .virtualMachine.resourceGroup')
  if [[ -n $INIRESULT ]];
  then
    read -r IP VMName RG <<< $(awk -F "[@/]" '{print $1, $(NF-1), $(NF)}' <<< "${INIRESULT}")
    SUBACCOUNTNAME=$(az account list --all | jq -r --arg ACCOUNTID "$1" '.[] | select (.id==$ACCOUNTID) | .name')
    echo "Search IP: ${PIP}"
    echo "SubAccount: ${SUBACCOUNTNAME}"
    echo "VirtualMachine Name: ${VMName}"
    echo "Resource Group: ${RG}"
    exit 1
  fi
} 


usage() { echo "Usage: $0 -i <PIP>" 1>&2; exit 1; }

declare PIP=""
# Initialize parameters specified from command line
while getopts "i:" arg; do
  case "${arg}" in
    i)
      PIP=${OPTARG}
      ;;
    esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$PIP" ]]; then
  echo "You need to provide your private IP"
  echo "Enter the private IP"
  read PIP
  [[ "${PIP:?}" ]]
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
  findVM $SUBACCOUNT $PIP
done