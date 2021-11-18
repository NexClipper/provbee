#!/bin/bash
beecmdpath="/usr/bin/beecmd"
beecmd_URL="https://raw.githubusercontent.com/NexClipper/provbee/master/scripts"
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
    k8s) 
    case ${beeCMD[2]} in
      ns) kubectl get ns ;;
      node) kubectl get node ;;
      svc) kubectl get svc -A ;;
      pod) kubectl get pod -A ;;
      *) echo "busybee beestatus k8s {NAMESPACE} ns/node/svc/pod";;
    esac
    ;;
    help|*) info "busybee beestatus hello" ;;
  esac
}

################################################################ value
while read beeA beeCMD ; do
  beeCMD=($beeCMD)
  curlcmd="curl -sL -G --data-urlencode"
  runbeeNS="${beeCMD[1]}"
  if [ "${beeCMD[1]}" = "" ]; then runbeeNS="nexclipper";fi 
  promsvr_DNS="http://nc-prometheus-server.$runbeeNS.svc.cluster.local"
  alertsvr_DNS="http://nc-prometheus-alertmanager.$runbeeNS.svc.cluster.local"
  promscale_DNS="http://nc-promscale-connector.$runbeeNS.svc.cluster.local:9201"
  case $beeA in
  #CMD_LIST_PRINT_START#
    ######### bee status check
    beestatus) provbeestatus ;;

    ######### NodePort search
    #nodesearch) nodesearch ;;

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
    
    ######### IP Search
    whoisip) source $beecmdpath/whoisip.sh ${beeCMD[@]} ;;

    ######### Helm charts 
    charts) source $beecmdpath/charts.sh ${beeCMD[@]} ;; 

    ######### MetricArk Info 
    metricark) source $beecmdpath/metricark.sh ${beeCMD[@]} ;; 

    ######### MetricArk PromQL 
    metricark_promql) source $beecmdpath/metricark_promql.sh ${beeCMD[@]} ;; 

    ######### MetricArk OpensatackNodes
    metricark_openstack_nodes) source $beecmdpath/metricark_openstack.sh ${beeCMD[@]} ;; 
    
    ######### MetricArk Api query 
    metricark) source $beecmdpath/metricark_api.sh ${beeCMD[@]} ;; 

    ######### Grafana API 
    grafana) source $beecmdpath/grafana.sh ${beeCMD[@]} ;;

  #CMD_LIST_PRINT_END#
    ## update busybee
    update) 
      curl -sL $beecmd_URL/busybee.sh -o /tmp/busybee
      chmod -R +x /tmp/busybee ;cp -Rfp /tmp/busybee /usr/bin/busybee ;rm -rf /tmp/busybee 
      cmdlist=$(awk -F" |/" '/\$beecmdpath\/.*.sh/{print $8}' /usr/bin/busybee)
      for i in $cmdlist ;do
	      curl -sL $beecmd_URL/beecmd/$i -o /usr/bin/beecmd/$i
	      chmod +x /usr/bin/beecmd/$i
      done
    ;;

    help|*) info "for NexClipper System....";;
  esac
done < <(echo $busybeecmd)


####################################Sample cmd
#kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, cap: .status.capacity}'
