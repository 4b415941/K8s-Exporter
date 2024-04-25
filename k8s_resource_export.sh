#!/bin/bash
set -e

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXPORT="$DIR/export"
echo "Exporting to $EXPORT"

# Backup previous export if exists
if [ -d "$EXPORT" ]; then
    PREVIOUS="$EXPORT.backup$(date +%FT%H%M%S)"
    mv -v "$EXPORT" "$PREVIOUS"
fi

mkdir "$EXPORT"

# Get all namespaces
namespaces=$(kubectl get namespaces -o=jsonpath='{.items[*].metadata.name}')

# Function to export resources
get_export() {
    NAMESPACE="$1"
    RESOURCE="$2"

    # Extract type and name
    type=$(echo $RESOURCE | awk -F '/' '{ print $1 }')
    name=$(echo $RESOURCE | awk -F '/' '{ print $2 }')

    # Define export directory
    [ -z "$NAMESPACE" ] && edir="$EXPORT/_/$type" || edir="$EXPORT/$NAMESPACE/$type"
    mkdir -p "$edir"

    echo -n "($type) $name, lines of yaml: "

    # Export resource to yaml file
    dest="$edir/$name"
    kubectl --namespace=$NAMESPACE get $RESOURCE --export -o=yaml \
      | sed "s/namespace: \"\"/namespace: \"$NAMESPACE\"/" \
      | tee "$dest.yml" \
      | wc -l

    # Check if the resource is managed
    grep -q 'kubernetes.io/created-by:' "$dest.yml" && echo " ... is a managed resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"

    # Check if the resource is a deployment
    [ -f "$dest.yml" ] && grep -q 'deployment.kubernetes.io/desired-replicas:' "$dest.yml" && echo "# ... is a deployment resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"

    # Check if the resource is generated
    [ -f "$dest.yml" ] && grep -q 'generateName:' "$dest.yml" && echo "# ... is a generated resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"

    # Check if the resource is owned
    [ -f "$dest.yml" ] && grep -q 'ownerReferences:' "$dest.yml" && echo "# ... is an owned resource" && \
        mv "$dest.yml" "$dest.k8s-created.yml"

    : # don't exit on missing created-by
}

# Export Custom Resource Definitions (CRDs)
crd=$( kubectl get crd -o=name | awk -F/ '{print $2}' )
echo "CRDs: $(echo "$crd" | wc -l) resources"
for RESOURCE in $crd; do
    get_export "" "customresourcedefinitions/$RESOURCE"
done

# Export non-namespaced resources
nonnamespaced=$(kubectl get persistentvolume -o=name)
echo "non-namespaced: $(echo "$nonnamespaced" | wc -l) resources"
for RESOURCE in $nonnamespaced; do
    get_export "" "$RESOURCE"
done

# Export resources in each namespace
for NAMESPACE in $namespaces; do
    mkdir -p "$EXPORT/$NAMESPACE"
    
    all=$( \
      kubectl --namespace=$NAMESPACE get all -o=name; \
      kubectl --namespace=$NAMESPACE get configmap -o=name; \
      kubectl --namespace=$NAMESPACE get persistentvolumeclaim -o=name; \
    )
    for C in $crd; do
        all="$all $(kubectl --namespace=$NAMESPACE get $C -o=name)";
    done
    echo "namespace $NAMESPACE: $(echo "$all" | wc -l) resources"
    for RESOURCE in $all; do
        get_export "$NAMESPACE" "$RESOURCE"
    done
done

# Add changes to git
git add -u "$EXPORT"
git add "$EXPORT"

echo "Export completed to $EXPORT"
