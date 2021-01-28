#!/bin/bash

#############################################
webstork_cmd(){
unset webstork_kubectl_run
webstork_yaml_url="https://raw.githubusercontent.com/NexClipper/webstork/main/services"
# alertmanager.yaml grafana.yaml prometheus.yaml pushgateway.yaml promlens.yaml
#busybee  webstork  create   nexclipper  NodePort  promlens
#busybee  $beeA     $beeB   $beeC       $beeD     $beeLAST(LASTA) $beeLAST(LASTB)
## namespace check
if [[ ${beeCMD[1]} == "" ]]; then fatal "P8s install namespace check"; fi #namespace=$beeC
## exposeType check
if [[ ${beeCMD[2]} =~ ^(NodePort|LoadBalancer|ClusterIP)$ ]]; then 
  webstork_expose_type=${beeCMD[2]}
else
  fatal ">> WebStork expose Type check (NodePort/LoadBalancer/ClusterIP)"
fi
## app name check
case ${beeCMD[3]} in
  alertmanager) webstork_app=${beeCMD[3]} ;;
  grafana) webstork_app=${beeCMD[3]} ;;
  prometheus) webstork_app=${beeCMD[3]} ;;
  pushgateway) webstork_app=${beeCMD[3]} ;;
  promlens) webstork_app=${beeCMD[3]} ;;
  *) fatal ">> WebStork App name check" ;; 
esac
## kubectl command run
webstork_cmd=${beeCMD[0],,}
case $webstork_cmd in
  create) 
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl create -f - 2>&1) 
  ;;
  edit) 
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl delete -f - 2>&1)
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl create -f - 2>&1)
  webstork_kubectl_run="edited"
  ;;
  delete)
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl delete -f - 2>&1)
  ;;
  *)
  fatal ">> WebStork cmd check (create/edit/delete) "
  ;;
esac

webstork_kubectl_status=$(echo $webstork_kubectl_run|awk '{print $NF}')
if [[ $webstork_kubectl_status =~ ^(created|deleted|edited) ]]; then
 webstork_kubectl_status=$webstork_kubectl_status
else
 webstork_kubectl_run=$(echo $webstork_kubectl_run|sed -e "s/\"//g")
 webstork_kubectl_status="$webstork_app $webstork_cmd FAIL : ${webstork_kubectl_run%%:*}"
fi 
###########################################################
## JSON CREATE ##
webstork_meta_name="ws-$webstork_app"
if [[ $webstork_expose_type == "NodePort" ]]; then
  webstork_ip_info=$(kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"\n"}{end}'|head -n1)
  nodeport_info=$(kubectl get svc -A -o jsonpath='{range .items[?(@.metadata.name == "'$webstork_meta_name'")].spec.ports[*]}{.name}{"\t"}{.nodePort}{"\n"}{end}')
elif [[ $webstork_expose_type == "LoadBalancer" ]]; then
  #webstork_ip_info=$(kubectl get svc -n nex-system -o jsonpath='{range $.items[*].status.loadBalancer.ingress[?(@.*)]}{.ip}{.hostname}{"\n"}{end}'|head -n1)
  webstork_ip_info=$(kubectl get svc/$webstork_meta_name -n nex-system -o jsonpath='{.status.loadBalancer.ingress[].ip}')
  while [ "$webstork_ip_info" == "" ]; do
    ipchkzzz=$((ipchkzzz+1))
    webstork_ip_info=$(kubectl get svc/$webstork_meta_name -n nex-system -o jsonpath='{.status.loadBalancer.ingress[].ip}')
    sleep 3
    if [ $ipchkzzz == "20" ]; then webstork_ip_info="Pending 60sec over"; fi
  done
  nodeport_info=$(kubectl get svc -A -o jsonpath='{range .items[?(@.metadata.name == "'$webstork_meta_name'")].spec.ports[*]}{.name}{"\t"}{.targetPort}{"\n"}{end}')
else
  webstork_ip_info="null"
fi
nodeport_count=$(echo "$nodeport_info"|wc -l)
local count=0
while [ $count -lt $nodeport_count ];
do
        count=$((count+1))
        webstork_app_name=$(echo "$nodeport_info"|sed -n ${count}p|awk '{print $1}')
        webstork_app_port=$(echo "$nodeport_info"|sed -n ${count}p|awk '{print $2}')
        #webstork_app_name=${webstork_app_name:=null};webstork_app_port=${webstork_app_port:=null}
        if [ $count -eq 1 ]; then
                local svc_json="{\"NAME\": \"${webstork_app_name:=null}\", \"PORT\": \"${webstork_app_port:=null}\"}"
        else
                local svc_json=",{\"NAME\": \"${webstork_app_name:=null}\", \"PORT\": \"${webstork_app_port:=null}\"}"
        fi
        if [[ $webstork_app_name == "promscale" ]]; then promsacle_port=${webstork_app_port};fi
        collect_json="${collect_json}${svc_json}"
done
#echo "[ { \"WEBSTORK_APP\":\"$webstork_meta_name\",\"WEBSTORK_STATUS\":\"$webstork_kubectl_status\",\"WEBSTORK_EXPOSE\":\"$webstork_expose_type\",\"WEBSTORK_IP\":\"$webstork_ip_info\",\"WEBSTORK_SVC\":["$collect_json"]} ]"|jq
if [[ $promsacle_port != "" ]]; then promlens_scale; fi
}
promlens_scale(){
  promlens_scale_replace=$(kubectl get deployment -n nexclipper nc-promlens -o json \
  | jq '.spec.template.spec.containers[0].command[2] = "'"http://${webstork_ip_info}:${promsacle_port}"'"' | kubectl replace -f -  2>&1)
}
webstork_cmd
################################ JSON print
TOTAL_JSON="{\"WEBSTORK_APP\":\"$webstork_meta_name\",\"WEBSTORK_STATUS\":\"$webstork_kubectl_status\",\"WEBSTORK_EXPOSE\":\"$webstork_expose_type\",\"WEBSTORK_IP\":\"$webstork_ip_info\",\"WEBSTORK_SVC\":["$collect_json"]}"
BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"beetype\":\"string\",\"data\":[$TOTAL_JSON]}]}"
echo $BEE_JSON
########