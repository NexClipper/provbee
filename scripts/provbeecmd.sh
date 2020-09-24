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
#NAMESPACE=monitoring
#NODEPORT=$(kubectl get svc -n $NAMESPACE -o jsonpath='{.items[?(@.metadata.name == "'$beechk'")].spec.ports[0].nodePort}')
NODEPORT=$(kubectl get svc -A -o jsonpath='{.items[?(@.metadata.name == "'$beechk'")].spec.ports[0].nodePort}')
NODEOSIMAGE=$(kubectl get node -o jsonpath='{.items[*].status.nodeInfo.osImage}')
if [[ $NODEPORT == "" ]]; then
        echo "Not find $beechk's nodePort"
        exit 1
else
    if [[ $NODEOSIMAGE == "Docker Desktop" ]]; then
        echo "localhost:$NODEPORT"
    else
        kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"':$NODEPORT'\n"}{end}'
    fi
fi
}


if [[ $beecmd == "beestatus" ]]; then
    provbeestatus
elif [[ $beecmd == "nodesearch" ]]; then
    nodesearch
else
    echo ":)"
fi