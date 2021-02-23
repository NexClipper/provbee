#!/bin/bash
beecmdpath="/usr/bin/beecmd"
busybeecmd=$@
beecmdlog="/tmp/busybee.log"
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
TYPE_JSON="string"
STATUS_JSON="OK"
## busybee cmd log
echo $(date "+%Y%m%d_%H%M%S") "|" $busybeecmd >> $beecmdlog
## information
info(){ echo -e '\033[92m[INFO]  \033[0m' "$@";}
warn(){ echo -e '\033[93m[WARN] \033[0m' "$@" >&2;}
fatal(){ echo -e '\033[91m[ERROR] \033[0m' "$@" >&2;exit 1;}
######################################################################################
withnexclipper(){
  nexns=$(kubectl get ns $KUBENAMESPACE |egrep -v NAME|wc -l)
  if [ $nexns -eq 0 ]; then fatal "$KUBENAMESPACE namespace check"; fi
}
withnexclipper
######################################################################################
provbeestatus(){
  case ${beeCMD[0]} in
    hello) echo "hi" ;;
    help|*) info "busybee beestatus hello" ;;
  esac
}

nodesearch(){
  case ${beeCMD[1]} in
    *)
      NODEPORT=$(kubectl get svc -A -o jsonpath='{.items[?(@.metadata.name == "'${beeCMD[1]}'")].spec.ports[0].nodePort}')
      NODEOSIMAGE=$(kubectl get node -o jsonpath='{.items[*].status.nodeInfo.osImage}')
      if [[ $NODEPORT == "" ]]; then
        fatal "Not found K8s Service : ${beeCMD[1]}"
      else
        if [[ $NODEOSIMAGE == "Docker Desktop" ]]; then
          echo "localhost:$NODEPORT"
        else
          kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"':$NODEPORT'\n"}{end}'|head -n1
        fi
      fi
    ;;
    help|HELP)  info "busybee nodesearch {K8s Service}" ;;
  esac
}


################################################################ value
while read beeA beeCMD ; do
  beeCMD=($beeCMD)
  curlcmd="curl -sL -G --data-urlencode"
  promsvr_DNS="http://nc-prometheus-server.${beeCMD[1]}.svc.cluster.local"
  alertsvr_DNS="http://nc-prometheus-alertmanager.${beeCMD[1]}.svc.cluster.local"
  case $beeA in
    ######### bee status check
    beestatus) provbeestatus ;;

    ######### NodePort search
    nodesearch) nodesearch ;;

    ######### tobs command
    tobs) source $beecmdpath/tobs.sh ${beeCMD[@]};;

    ######### k8s API
    k8s) source $beecmdpath/k8s_api.sh ${beeCMD[@]} ;;

    ######### p8s API
    p8s) source $beecmdpath/p8s_api.sh ${beeCMD[@]} ;;

    ######### WebStork command
    webstork) source $beecmdpath/webstork.sh ${beeCMD[@]} ;;

    ######### Global view API
    gstatus) source $beecmdpath/gstatus.sh ${beeCMD[@]} ;;
    
    ## update busybee
    update) 
    curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/scripts/busybee.sh -o /tmp/busybee
    cp -Rfp /tmp/busybee /usr/bin/busybee
    chmod -R +x /usr/bin/beecmd/
    chmod +x /usr/bin/busybee
    rm -rf /tmp/busybee 
    ;;

    ############## help
    help|*) info "for NexClipper System....";;
  esac
done < <(echo $busybeecmd)