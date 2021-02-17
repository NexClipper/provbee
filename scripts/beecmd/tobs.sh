#!/bin/bash


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
      echo "INST_RUN" > /tmp/tobsinst
      helm repo add nexclipper https://nexclipper.github.io/helm-charts/
      helm repo update
      tobs install -n nc -c nexclipper/tobs --namespace ${beeCMD[1]} $filepath
    ############ tobs install chk start
      tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l)
        sleep 3
      while [ $tobs_status != "0" ]; do
        tobszzz=$((tobszzz+1))
        tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l) 
        sleep 3
        if [ $tobszzz == "99" ]; then warn "FAIL" > /tmp/tobsinst ; fatal "tobs install checking time out(300s)" ; fi
      done
      info "Tobs install OK"
      echo "TobsOK" > /tmp/tobsinst
      if [[ $(cat /tmp/tobsinst) == "TobsOK" ]]; then
        provbeens=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
        provbeesa="nexc"
        curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/install/yaml/webstork.yaml \
        | sed -e "s#\${KUBENAMESPACE}#$provbeens#g" \
        | sed -e "s#\${KUBESERVICEACCOUNT}#$provbeesa#g" \
        | kubectl create -f - 2>&1
      else
        fatal "Webstork start FAIL"
      fi
    ;;
    instpw)
      echo ${beeCMD[2]} > /tmp/gfpasswd
    ;;
    install_chk)
      tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l) 
      cat /tmp/tobsinst
    ;; 
    uninstall)
      tobs uninstall -n nc --namespace ${beeCMD[1]} $filepath
      tobs helm delete-data -n nc --namespace ${beeCMD[1]}
    ;;
    passwd)
      chpasswd="${beeCMD[2]}"
      tobs_status=$(kubectl get pods -n ${beeCMD[1]} 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l)
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
tobscmd
################Print JSON
beejson(){
if [[ $TYPE_JSON == "json" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beetype\":\"${TYPE_JSON}\",\"data\":[${TOTAL_JSON}]}]}"
elif [[ $TYPE_JSON == "base64" ]] || [[ $TYPE_JSON == "string" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}]}"
else
  BEE_JSON="Bee!"
fi
echo $BEE_JSON
}
#beejson