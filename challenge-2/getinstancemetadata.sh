#!/bin/bash
#echo "Enter meta data of an instance from the below list: $1"
#echo "Examples: service-accounts disks licenses network-interfaces scheduling""
curl -s "http://metadata.google.internal/computeMetadata/v1/instance/$1/?recursive=true&alt=json" -H "Metadata-Flavor: Google"| jq
