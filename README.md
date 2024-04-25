# K8s-Exporter
 This repository contains a Bash script for exporting Kubernetes cluster resources to YAML files. The script automates the process of exporting resources, including Custom Resource Definitions (CRDs), non-namespaced resources, and resources within each namespace. It also provides features such as backing up previous exports and adding changes to Git. Simply run the script to export resources from your Kubernetes cluster and manage them efficiently.

## Usage

1. Copy or download this script to use in your own Kubernetes cluster.
2. Grant execution permission to the script: `chmod +x export_resources.sh`
3. Run the script to export resources: `./export_resources.sh`
4. The script saves the resources as YAML files to the specified export directory.

## Features

- Backs up previous exports.
- Exports Custom Resource Definitions (CRDs) and non-namespaced resources.
- Exports resources in each namespace.
- Adds changes to Git.

## Requirements

- This script uses the `kubectl` command to access Kubernetes clusters. Therefore, `kubectl` must be installed.