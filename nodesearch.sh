#!/bin/bash
PODNAME=$1
if [[ $PODNAME == "" ]]; then echo "$0 PODNAME "; exit 1; fi
NODEPORT=$(kubectl get svc -o jsonpath='{.items[?(@.metadata.name == "'$PODNAME'")].spec.ports[0].nodePort}' -n monitoring)
if [[ $NODEPORT == "" ]]; then
        echo "Not find $PODNAME's nodePort"
        exit 1
else
        kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"':$NODEPORT'\n"}{end}'
fi