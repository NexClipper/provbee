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
    ## JSON
      tobsinst_status="TobsOK";beejson
      
      #temp. old message
      #echo "TobsOK"
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
      beejson
    ;;
    passwd)
      chpasswd="${beeCMD[2]}"
      tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |egrep ^nc-|egrep -v 'unning.|ompleted'|wc -l)
      if [ $tobs_status -ne 0 ]; then
        fatal "Grafana service is status RED"
      else
      ## first GF passwd
        if [ -f /tmp/gfpasswd ]; then chpasswd=$(cat /tmp/gfpasswd); rm -rf /tmp/gfpasswd; fi
      ## GF passwd change
        tobs -n nc --namespace ${beeCMD[1]} grafana change-password $chpasswd >/tmp/gra_pwd 2>&1
        pwchstatus=$(cat /tmp/gra_pwd |grep successfully | wc -l)
        if [ $pwchstatus -eq 1 ]; then 
          sed -i "s/passwd ${beeCMD[1]} $chpasswd.*/passwd ${beeCMD[1]} :)/g" $beecmdlog
          info "Grafana password change OK"
        else 
          sed -i "s/passwd ${beeCMD[1]} $chpasswd.*/passwd ${beeCMD[1]} :(/g" $beecmdlog
          fatal "Grafana password change FAIL"
        fi
      fi
    ;;
    help|*) info "busybee tobs {install/uninstall} {NAMESPACE} {opt.FILEPATH}";;
  esac
}

beejson(){
################################ JSON print
TYPE_JSON="json"
#P8S_INSTALL

TOTAL_JSON="{\"P8S_INSTALL\":\"$tobsinst_status\"${webstork_status}}"
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