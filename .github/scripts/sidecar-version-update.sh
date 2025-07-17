#!/bin/bash

# Copyright 2025 DELL Inc. or its subsidiaries.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script updates the sidecar versions across CSM-operator files

# Fetch the latest release information from the GitHub API for all the sidecars
provisioner_ver=$(curl --silent "https://api.github.com/repos/kubernetes-csi/external-provisioner/releases/latest" | grep -oP '"tag_name": "\K(.*?)(?=")')
attacher_ver=$(curl --silent "https://api.github.com/repos/kubernetes-csi/external-attacher/releases/latest" | grep -oP '"tag_name": "\K(.*?)(?=")')
snapshotter_ver=$(curl --silent "https://api.github.com/repos/kubernetes-csi/external-snapshotter/releases/latest" | grep -oP '"tag_name": "\K(.*?)(?=")')
registrar_ver=$(curl --silent "https://api.github.com/repos/kubernetes-csi/node-driver-registrar/releases/latest" | grep -oP '"tag_name": "\K(.*?)(?=")')
health_monitor_ver=$(curl --silent "https://api.github.com/repos/kubernetes-csi/external-health-monitor/releases/latest" | grep -oP '"tag_name": "\K(.*?)(?=")')
resizer_ver=$(curl --silent "https://api.github.com/repos/kubernetes-csi/external-resizer/releases/latest" | grep -oP '"tag_name": "\K(.*?)(?=")')

# Internal images and hence we will access quay.io/dell repos to get the latest version
sdc_ver=$(https://quay.io/api/v1/repository/dell/storage/powerflex/sdc/tag/?limit=100 | jq -r '.tags[].name' | sort -V | tail -n 1)
metadata_retriever_ver=$(https://quay.io/api/v1/repository/dell/container-storage-modules/csi-metadata-retriever/tag/?limit=100 | jq -r '.tags[].name' | sort -V | tail -n 1)

echo "provisioner latest version: $provisioner_ver"
echo "attacher latest version: $attacher_ver"
echo "snapshotter latest version: $snapshotter_ver"
echo "registrar latest version: $registrar_ver"
echo "health_monitor latest version: $health_monitor_ver"
echo "resizer latest version: $resizer_ver"

echo "metadata_retriever latest version: $metadata_retriever_ver"
echo "sdc latest version: $sdc_ver"

cd $GITHUB_WORKSPACE

for sidecar in {attacher,provisioner,snapshotter,registrar,resizer,external-health-monitor,sdc,metadata-retriever}
  do
    echo "Updating sidecar version for -->> $sidecar"
    old_sidecar_ver=$(cat ./operatorconfig/driverconfig/common/default.yaml | grep $sidecar | egrep 'registry.k8s.io|quay.io'  | awk '{print $2}')
    old_sidecar_sub_string=$(echo $old_sidecar_ver | awk -F':' '{print $1}')

    files_to_be_modified=$(grep -rl $old_sidecar_ver)

       for file in $files_to_be_modified
         do
            if [ $sidecar == 'attacher' ]; then
              sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${attacher_ver}|g" $file
            elif [ $sidecar == 'provisioner' ]; then
              sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${provisioner_ver}|g" $file
            elif [ $sidecar == 'snapshotter' ]; then
              sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${snapshotter_ver}|g" $file
            elif [ $sidecar == 'registrar' ]; then
              sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${registrar_ver}|g" $file
            elif [ $sidecar == 'resizer' ]; then
              sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${resizer_ver}|g" $file
            elif [ $sidecar == 'external-health-monitor' ]; then
             sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${health_monitor_ver}|g" $file
            elif [ $sidecar == 'sdc' ]; then
              sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${sdc_ver}|g" $file
            elif [ $sidecar == 'metadata-retriever' ]; then
              sed -i "s|${old_sidecar_ver}|${old_sidecar_sub_string}:${metadata_retriever_ver}|g" $file
            fi
         done
         echo "Done updating sidecar version for -->> $sidecar"

  done
  echo "SIDECAR Version update complete"