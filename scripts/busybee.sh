#!/bin/bash
beecmdpath="/usr/bin/beecmd"
busybeecmd=$@
beecmdlog="/tmp/busybee.log"
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
echo $(date "+%Y%m%d_%H%M%S") "|" $busybeecmd >> $beecmdlog
#beeA -> podsearch, beestatus, tobs etc
#beeB -> grafana, hello, etc..
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
  case $beeB in
    hello) echo "hi" ;;
    help|*) info "busybee beestatus hello" ;;
  esac
}

nodesearch(){
  case $beeB in
    *)
      #NODEPORT=$(kubectl get svc -n $NAMESPACE -o jsonpath='{.items[?(@.metadata.name == "'$beecmd'")].spec.ports[0].nodePort}')
      NODEPORT=$(kubectl get svc -A -o jsonpath='{.items[?(@.metadata.name == "'$beeB'")].spec.ports[0].nodePort}')
      NODEOSIMAGE=$(kubectl get node -o jsonpath='{.items[*].status.nodeInfo.osImage}')
      if [[ $NODEPORT == "" ]]; then
        fatal "Not found K8s Service : $beeB"
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
while read beeA beeB beeC beeD beeLAST ; do
  curlcmd="curl -sL -G --data-urlencode"
  promsvr_DNS="http://nc-prometheus-server.$beeC.svc.cluster.local"
  alertsvr_DNS="http://nc-prometheus-alertmanager.$beeC.svc.cluster.local"
  case $beeA in
    ######### bee status check
    beestatus)  provbeestatus ;;

    ######### NodePort search
    nodesearch) nodesearch ;;

    ######### tobs command
    tobs) tobscmd ;;

    ######### k8s API
    k8s) k8s_api ;;

    ######### p8s API
    p8s) p8s_api ;;

    ######### WebStork command
    webstork) webstork_cmd ;;

    ############## help
    help|*) info "for NexClipper System....";;
  esac
done < <(echo $busybeecmd)
