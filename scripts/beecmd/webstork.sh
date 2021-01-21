#!/bin/bash







#############################################
webstork_cmd(){
unset webstork_kubectl_run
webstork_yaml_url="https://raw.githubusercontent.com/NexClipper/webstork/main/services"
# alertmanager.yaml grafana.yaml prometheus.yaml pushgateway.yaml promlens.yaml
#busybee  webstork  create   nexclipper  NodePort  promlens
#busybee  webstork  $GETCMD $PROVNS     $GETTYPE  $GETAPP ###### yaml FILE
#busybee  $beeA     $beeB   $beeC       $beeD     $beeLAST(LASTA) $beeLAST(LASTB)
if [[ ${beeB,,} =~ ^(create|edit|delete)$ ]]; then
  webstork_cmd=${beeB,,}
else
  fatal ">> WebStork cmd check (create/edit/delete) "
fi
if [[ $beeC == "" ]]; then fatal "P8s install namespace check"; fi #namespace=$beeC
if [[ $beeD =~ ^(NodePort|LoadBalancer|ClusterIP)$ ]]; then 
  webstork_expose_type=$beeD
else
  fatal ">> WebStork expose Type check (NodePort/LoadBalancer/ClusterIP)"
fi
if [[ $beeLAST != "" ]]; then
  while read LASTA LASTB LASTC; do
    case $LASTA in
      alertmanager) webstork_app=$LASTA ;;
      grafana) webstork_app=$LASTA ;;
      prometheus) webstork_app=$LASTA ;;
      pushgateway) webstork_app=$LASTA ;;
      promlens) webstork_app=$LASTA ;;
      *) fatal ">> WebStork App name check" ;; 
    esac
    #if [[ $LASTB != "" ]]; then webstork_app_yaml=$LASTB; fi
  done < <(echo $beeLAST)
else
  fatal ">> WebStork App name check"
fi
#curl -sL $webstork_yaml_url/$webstork_app.yaml|sed -e "s#\${EXPOSETYPE}#$webstork_expose_type#g" \
#| kubectl $webstork_cmd -f - > $webstork_tmp_status 2>&1
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
 webstork_kubectl_status="webstork $webstork_app $webstork_cmd FAIL"
fi 
###########################################################
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