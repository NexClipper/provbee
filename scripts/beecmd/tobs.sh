#!/bin/bash
tobslog="/tmp/tobs_busybee.log"

#############################################
tobscmd(){
  case ${beeCMD[0]} in
    install)
    ## install value file decoding
      sed -i 's/\\n//g' /tmp/${beeCMD[2]}.base64; base64 -d /tmp/${beeCMD[2]}.base64 > /tmp/${beeCMD[2]}; filepath="-f /tmp/${beeCMD[2]}"
    ## helm chart update & tobs install 
      helm repo add nexclipper https://nexclipper.github.io/helm-charts/ >> $tobslog 2>&1
      helm repo update >> $tobslog 2>&1
      tobs install -n nc -c nexclipper/tobs --namespace ${beeCMD[1]} $filepath >> $tobslog 2>&1
    ############ tobs install chk start
      if [[ $(kubectl get ns ${beeCMD[1]} 2>&1|grep "NotFound") != ""  ]]; then 
        fatal "Tobs install FAIL"
      else
        tobslogchk=$(cat $tobslog|egrep "^Error:")
        if [[ $tobslogchk != "" ]]; then fatal "$(echo $tobslogchk| sed -e 's#"#@#g' -e '{N;s/\n//}')";fi  
      fi

    ##  
      tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |egrep ^nc-|egrep -v 'unning.|ompleted'|wc -l)
        sleep 3
      while [ $tobs_status != "0" ]; do
        tobszzz=$((tobszzz+1))
        tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |egrep ^nc-|egrep -v 'unning.|ompleted'|wc -l) 
        sleep 3
        if [ $tobszzz == "99" ]; then STATUS_JSON="FAIL"; tobsinst_status="tobs running check Time out";beejson; exit 0;fi
      done
    ###
    ## Webstork Install
      provbeens=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
      provbeesa="nexc"
      webstork_inst=$(curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/install/yaml/webstork.yaml \
      | sed -e "s#\${KUBENAMESPACE}#$provbeens#g" \
      | sed -e "s#\${KUBESERVICEACCOUNT}#$provbeesa#g" \
      | kubectl create -f - 2>&1)
      if [[ $(echo $webstork_inst|grep "AlreadyExists") != "" ]]; then webstork_inst="AlreadyExists";fi 
      #webstork_inst_status=$(echo $webstork_inst|awk '{print $NF}')
      webstork_status=",\"WEBSTORK_INSTALL\": \"${webstork_inst##*\ }\""
    ## GLOBAL VIEW
      #####  kubectl patch service -n ${beeCMD[1]} nc-promscale-connector --type=json -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30000}]' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'
      svc_type=$(kubectl get service nc-promscale-connector -n ${beeCMD[1]} -o jsonpath='{.spec.type}' 2>/dev/null)
      if [[ $svc_type == "NodePort" ]]; then
        nodeport_ip_info=$(kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"\n"}{end}'|head -n1)
        nodeport_port_info=$(kubectl get service nc-promscale-connector -n ${beeCMD[1]} -o jsonpath='{range .spec.ports[*]}{.nodePort}{"\n"}{end}')
        promscale_info="${nodeport_ip_info}:${nodeport_port_info}"
      elif [[ $svc_type == "LoadBalancer" ]]; then
        while [ "$lb_ip_info" == "" ]; do
          ipchkzzz=$((ipchkzzz+1))
          lb_ip_info=$(kubectl get service nc-promscale-connector -n ${beeCMD[1]} -o jsonpath='{.status.loadBalancer.ingress[]}'|jq -r 'if .ip !=null then (.ip) else (.hostname) end')
          sleep 3
          if [ $ipchkzzz == "20" ]; then STATUS_JSON="FAIL";lb_ip_info="Pending"; fi
        done  
        lb_port_info=$(kubectl get service nc-promscale-connector -n ${beeCMD[1]} -o jsonpath='{range .spec.ports[*]}{.port}{"\n"}{end}')
        promscale_info="${lb_ip_info}:${lb_port_info}"
      fi
      global_view=",\"GLOBAL_VIEW_ENDPOINT\": \"${promscale_info:=null}\""
    
    ## JSON
      tobsinst_status="TobsOK"
      TOTAL_JSON="{\"P8S_INSTALL\":\"$tobsinst_status\"${webstork_status}${global_view}}"
      beejson
    ;;
    check)
      if [[ $(kubectl get ns ${beeCMD[1]} 2>&1|grep "NotFound") != ""  ]]; then fatal "Tobs not installed : ${beeCMD[1]}";fi 
      tobs_nschk=$(kubectl get po -n ${beeCMD[1]} 2>&1)
      if [[ $(echo ${tobs_nschk%%found*}) == "No resources" ]]; then
        STATUS_JSON="ERROR"; tobsinst_status="$tobs_nschk"
        TOTAL_JSON="{\"P8S_INSTALL\":\"$tobsinst_status\"}"
        beejson;exit 0
      fi 
      tobs_chk=$(kubectl get po -n ${beeCMD[1]} 2>/dev/null |egrep ^nc-|egrep -v 'unning.|ompleted'|awk '{print $1"-"$3}')
      if [[ $tobs_chk == "" ]]; then
        tobsinst_status="TobsOK"
        webstork_chk=$(kubectl get pod -n ${KUBENAMESPACE} 2>/dev/null | egrep ^webstork-|awk '{print $3}')
        if [[ $webstork_chk == "Running" ]]; then 
          webstork_status=",\"WEBSTORK_INSTALL\": \"${webstork_chk}\""
        else
          STATUS_JSON="ERROR"; webstork_status=",\"WEBSTORK_INSTALL\": \"${webstork_chk:=not_installed}\"" 
        fi
      else
        STATUS_JSON="ERROR"; tobsinst_status="$tobs_chk"
      fi  
      TOTAL_JSON="{\"P8S_INSTALL\":\"$tobsinst_status\"${webstork_status}}"
      beejson
      ;;
    uninstall)
      #tobs uninstall -n nc --namespace ${beeCMD[1]} $filepath >> $tobslog 2>&1
      tobs uninstall -n nc --namespace ${beeCMD[1]} >> $tobslog 2>&1
      tobs helm delete-data -n nc --namespace ${beeCMD[1]} >> $tobslog 2>&1
      #kubectl delete ns ${beeCMD[1]}
      tobsinst_status="Deleted"
      webstork_inst=$(kubectl delete deployment/webstork -n ${KUBENAMESPACE} 2>&1|egrep -v "NotFound")
      if [[ $webstork_inst == "" ]]; then webstork_inst="Not_Installed"; fi
      webstork_status=",\"WEBSTORK_INSTALL\": \"${webstork_inst##*\ }\""  
      TOTAL_JSON="{\"P8S_INSTALL\":\"$tobsinst_status\"${webstork_status}}"
      beejson
    ;;
    passwd)
      chpasswd="${beeCMD[2]}"
      ## Grafana status chk.
      if [[ $(kubectl get ns ${beeCMD[1]} 2>&1|grep "NotFound") != ""  ]]; then fatal "Tobs not installed(namespace : ${beeCMD[1]} )"; fi
      tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |egrep ^nc-|egrep -v 'unning.|ompleted'|wc -l)
      if [ $tobs_status -ne 0 ]; then fatal "Grafana service is status RED"; fi
      ## GF passwd change
      pwchstatus=$(tobs -n nc --namespace ${beeCMD[1]} grafana change-password $chpasswd 2>&1 | sed -e 's#"#@#g')
      if [[ $(echo $pwchstatus|grep successfully) != "" ]]; then
        sed -i "s/passwd ${beeCMD[1]} $chpasswd.*/passwd ${beeCMD[1]} :)/g" $beecmdlog
        grafana_pwd_status="successfully"
      else
        sed -i "s/passwd ${beeCMD[1]} $chpasswd.*/passwd ${beeCMD[1]} :(/g" $beecmdlog
        STATUS_JSON="FAIL"; grafana_pwd_status="$pwchstatus"
      fi
      TOTAL_JSON="{\"GF_STATUS\":\""${grafana_pwd_status}"\"}"
      beejson
    ;;
    help|*) info "busybee tobs {install/uninstall} {NAMESPACE} {opt.FILEPATH}";;
  esac
}

beejson(){
################################ JSON print
TYPE_JSON="json"
#P8S_INSTALL

################Print JSON
if [[ $TYPE_JSON == "json" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beetype\":\"${TYPE_JSON}\",\"data\":[${TOTAL_JSON}]}]}"
elif [[ $TYPE_JSON == "base64" ]] || [[ $TYPE_JSON == "string" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}]}"
else
  BEE_JSON="Bee!"
fi
echo $BEE_JSON
}
tobscmd