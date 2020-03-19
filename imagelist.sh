#!/usr/bin/env bash

az image list --subscription 71294299-6fce-468f-a7aa-3bc74df54a16 | jq -r '
map(select(.resourceGroup=="SI-UE2-VIRTUALMACHINEIMAGES-RG"))
  | map({name: .name, location: .location})
  | sort_by(.name)
  | group_by(.location)
  | map(.[0:-7])
  | flatten
  | .[]
  | [.name, .location]
  | @csv
'
