#!/bin/bash
tobslog="/tmp/tobs_busybee.log"

#############################################
tobscmd(){
  #tobs $beecmd -n nc --namespace $beenamespace -f provbeetmp
  #if [[ $beeC == "" ]]; then beeC="nexclipper"; fi
  if [[ ${beeCMD[2]} =~ ^NexClipper\..*$ ]]; then
    sed -i 's/\\n//g' /tmp/${beeCMD[2]}.base64
    base64 -d /tmp/${beeCMD[2]}.base64 > /tmp/${beeCMD[2]}
    filepath="-f /tmp/${beeCMD[2]}"
  elif [[ $provbeetmp =~ ^NexClipper_GLOBAL\..*$ ]]; then
    sed -i 's/\\n//g' /tmp/${beeCMD[2]}.base64
    base64 -d /tmp/${beeCMD[2]}.base64 > /tmp/${beeCMD[2]}
    filepath="-f /tmp/${beeCMD[2]}" 
    GLOBAL_VIEW="Y"
  fi
  case ${beeCMD[0]} in
    install) 
      helm repo add nexclipper https://nexclipper.github.io/helm-charts/ >> $tobslog 2>&1
      helm repo update >> $tobslog 2>&1
      tobs install -n nc -c nexclipper/tobs --namespace ${beeCMD[1]} $filepath >> $tobslog 2>&1
    ############ tobs install chk start
      if [[ $(kubectl get ns ${beeCMD[1]} 2>&1|grep "NotFound") != ""  ]]; then fatal "Tobs install FAIL"; fi
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
      | kubectl create -f - 2>&1|egrep -v "AlreadyExists")
      if [[ $webstork_inst == "AlreadyExists" ]]; then webstork_inst="AlreadyExists";fi 
      #webstork_inst_status=$(echo $webstork_inst|awk '{print $NF}')
      webstork_status=",\"WEBSTORK_INSTALL\": \"${webstork_inst##*\ }\""
    ## GLOBAL VIEW
      #if [[ $GLOBAL_VIEW == "Y" ]]; then kubectl patch service -n nex-system ws-grafana --type=json -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32600}]';fi 
    if [[ $GLOBAL_VIEW == "Y" ]]; then echo "GLOBAL_VIEW" > /tmp/ggggggggg ;fi
      ## JSON
      tobsinst_status="TobsOK"
      TOTAL_JSON="{\"P8S_INSTALL\":\"$tobsinst_status\"${webstork_status}}"
      beejson
    ;;
    check)
      tobs_nschk=$(kubectl get po -n ${beeCMD[1]} 2>&1)
      if [[ $(echo ${tobs_nschk%%found*}) == "No resources" ]]; then
        STATUS_JSON="ERROR"; tobsinst_status="$tobs_nschk";beejson;exit 0
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