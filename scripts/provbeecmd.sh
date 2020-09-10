#!/bin/bash
beecmd=$1
#beecmd -> podsearch, beestatus, etc

beechk=$2
#beechk -> grafana, hello, etc..

provbeestatus(){
if [[ $beechk == "hello" ]]; then
	echo "hi"
fi
}

nodesearch(){
NAMESPACE=monitoring
NODEPORT=$(kubectl get svc -n $NAMESPACE -o jsonpath='{.items[?(@.metadata.name == "'$beechk'")].spec.ports[0].nodePort}')
if [[ $NODEPORT == "" ]]; then
        echo "Not find $beechk's nodePort"
        exit 1
else
        kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"':$NODEPORT'\n"}{end}'
fi
}


if [[ $beecmd == "beestatus" ]]; then
    provbeestatus
elif [[ $beecmd == "nodesearch" ]]; then
    nodesearch
else
    echo ":)"
fi