#!/bin/bash
busybeecmd=$@

#beeA -> podsearch, beestatus, tobs etc
#beeB -> grafana, hello, etc..

provbeestatus(){
    case $beeB in
        hello) echo "hi" ;;
        help|*)  echo "busybee beestatus hello" ;;
    esac
}

nodesearch(){
    case $beeB in
        *)
            #NODEPORT=$(kubectl get svc -n $NAMESPACE -o jsonpath='{.items[?(@.metadata.name == "'$beecmd'")].spec.ports[0].nodePort}')
            NODEPORT=$(kubectl get svc -A -o jsonpath='{.items[?(@.metadata.name == "'$beeB'")].spec.ports[0].nodePort}')
            NODEOSIMAGE=$(kubectl get node -o jsonpath='{.items[*].status.nodeInfo.osImage}')
            if [[ $NODEPORT == "" ]]; then
                    echo "Not found K8s Service : $beeB"
                    exit 1
            else
                if [[ $NODEOSIMAGE == "Docker Desktop" ]]; then
                    echo "localhost:$NODEPORT"
                else
                    kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"':$NODEPORT'\n"}{end}'
                fi
            fi
            ;;
        help|HELP)  echo "busybee nodesearch {K8s Service}" ;;
    esac
}

tobscmd(){
    #tobs $beecmd -n nc --namespace $beenamespace -f provbeetmp 
    if [[ $beeC == "" ]]; then beeC="nexclipper"; fi 
    if [[ $beeD =~ ^NexClipper\..*$ ]]; then filepath="-f /tmp/$beeD"; fi
    case $beeB in 
        install) tobs install -n nc --namespace $beeC $filepath;; 
        uninstall) tobs uninstall -n nc --namespace $beeC $filepath;;
        help|*) echo "busybee tobs {install/uninstall} {NAMESPACE} {opt.FILEPATH}";;
    esac
}



while read beeA beeB beeC beeD beeLAST ; do
    case $beeA in
        ######### bee status check
        beestatus)  provbeestatus ;;
        
        ######### NodePort search
        nodesearch) nodesearch ;;

        ######### tobs command        
        tobs)   tobscmd ;;

        ############## help
        help|*) echo "beestatus/nodesearch/tobs ...";;
    esac
done < <(echo $busybeecmd)
