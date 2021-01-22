#!/bin/bash

#############################################
webstork_cmd(){
unset webstork_kubectl_run
webstork_yaml_url="https://raw.githubusercontent.com/NexClipper/webstork/main/services"
# alertmanager.yaml grafana.yaml prometheus.yaml pushgateway.yaml promlens.yaml
#busybee  webstork  create   nexclipper  NodePort  promlens
#busybee  $beeA     $beeB   $beeC       $beeD     $beeLAST(LASTA) $beeLAST(LASTB)
## command check
if [[ ${beeCMD[0],,} =~ ^(create|edit|delete)$ ]]; then
  webstork_cmd=${beeCMD[0],,}
else
  fatal ">> WebStork cmd check (create/edit/delete) "
fi
## namespace check
if [[ ${beeCMD[1]} == "" ]]; then fatal "P8s install namespace check"; fi #namespace=$beeC
## exposeType check
if [[ ${beeCMD[2]} =~ ^(NodePort|LoadBalancer|ClusterIP)$ ]]; then 
  webstork_expose_type=${beeCMD[2]}
else
  fatal ">> WebStork expose Type check (NodePort/LoadBalancer/ClusterIP)"
fi
## app name check
if [[ ${beeCMD[3]} != "" ]]; then
    case ${beeCMD[3]} in
      alertmanager) webstork_app=${beeCMD[3]} ;;
      grafana) webstork_app=${beeCMD[3]} ;;
      prometheus) webstork_app=${beeCMD[3]} ;;
      pushgateway) webstork_app=${beeCMD[3]} ;;
      promlens) webstork_app=${beeCMD[3]} ;;
      *) fatal ">> WebStork App name check" ;; 
    esac
else
  fatal ">> WebStork App name check"
fi
## kubectl command run
if [[ $webstork_cmd == "create" ]]; then
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl create -f - 2>&1)
elif [[ $webstork_cmd == "edit" ]]; then 
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl delete -f - 2>&1)
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl create -f - 2>&1)
elif [[ $webstork_cmd == "delete" ]]; then
  webstork_kubectl_run=$(curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" | kubectl delete -f - 2>&1)
fi
webstork_kubectl_status=$(echo $webstork_kubectl_run|awk '{print $NF}')
if [[ $webstork_kubectl_status =~ ^(created|deleted) ]]; then
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
elif [[ $webstork_expose_type == "LoadBalancer" ]]; then
  webstork_ip_info=$(kubectl get svc -n nex-system -o jsonpath='{range $.items[*].status.loadBalancer.ingress[?(@.*)]}{.ip}{.hostname}{"\n"}{end}'|head -n1)
else
  webstork_ip_info="null"
fi
nodeport_info=$(kubectl get svc -A -o jsonpath='{range .items[?(@.metadata.name == "'$webstork_meta_name'")].spec.ports[*]}{.name}{"\t"}{.'${webstork_expose_type,}'}{"\n"}{end}')
nodeport_count=$(echo "$nodeport_info"|wc -l)
local count=0
while [ $count -lt $nodeport_count ];
do
        count=$((count+1))
        webstork_app_name=$(echo "$nodeport_info"|sed -n ${count}p|awk '{print $1}')
        webstork_app_port=$(echo "$nodeport_info"|sed -n ${count}p|awk '{print $2}')
        webstork_app_name=${webstork_app_name:=null};webstork_app_port=${webstork_app_port:=null}
        if [ $count -eq 1 ]; then
                local svc_json="{\"NAME\": \"${webstork_app_name}\", \"PORT\": \"${webstork_app_port}\"}"
        else
                local svc_json=",{\"NAME\": \"${webstork_app_name}\", \"PORT\": \"${webstork_app_port}\"}"
        fi
        collect_json="${collect_json}${svc_json}"
done
echo "[ { \"WEBSTORK_APP\":\"$webstork_meta_name\",\"WEBSTORK_STATUS\":\"$webstork_kubectl_status\",\"WEBSTORK_EXPOSE\":\"$webstork_expose_type\",\"WEBSTORK_IP\":\"$webstork_ip_info\",\"WEBSTORK_SVC\":["$collect_json"]} ]"|jq
}
webstork_cmd
########