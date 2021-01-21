#!/bin/bash







#############################################
tobscmd(){
  #tobs $beecmd -n nc --namespace $beenamespace -f provbeetmp
  if [[ $beeC == "" ]]; then beeC="nexclipper"; fi
  if [[ $beeB == "passwd" ]]; then chpasswd="$beeD"; fi
  if [[ $beeD =~ ^NexClipper\..*$ ]]; then
    sed -i 's/\\n//g' /tmp/$beeD.base64
    base64 -d /tmp/$beeD.base64 > /tmp/$beeD
    filepath="-f /tmp/$beeD"
  fi
  case $beeB in
    install) 
      echo "INST_RUN" > /tmp/tobsinst
      tobs install -n nc --namespace $beeC $filepath
    ############ tobs install chk start
      tobs_status=$(kubectl get pods -n $beeC 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l)
        sleep 3
      while [ $tobs_status != "0" ]; do
        tobszzz=$((tobszzz+1))
        tobs_status=$(kubectl get pods -n $beeC 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l) 
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
      echo $beeD > /tmp/gfpasswd
    ;;
    install_chk)
      tobs_status=$(kubectl get pods -n $beeC 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l) 
      cat /tmp/tobsinst
    ;; 
    uninstall)
      tobs uninstall -n nc --namespace $beeC $filepath
      tobs helm delete-data -n nc --namespace $beeC
    ;;
    passwd)
      tobs_status=$(kubectl get pods -n $beeC 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l)
      if [ $tobs_status -ne 0 ]; then
        fatal "Grafana service is status RED"
      else
      ## first GF passwd
        if [ -f /tmp/gfpasswd ]; then chpasswd=$(cat /tmp/gfpasswd); rm -rf /tmp/gfpasswd; fi
      ## GF passwd change
        tobs -n nc --namespace $beeC grafana change-password $chpasswd >/tmp/gra_pwd 2>&1
        pwchstatus=$(cat /tmp/gra_pwd |grep successfully | wc -l)
        if [ $pwchstatus -eq 1 ]; then 
          sed -i "s/passwd $beeC $chpasswd.*/passwd $beeC :)/g" $beecmdlog
          info "Grafana password change OK"
        else 
          sed -i "s/passwd $beeC $chpasswd.*/passwd $beeC :(/g" $beecmdlog
          fatal "Grafana password change FAIL"
        fi
      fi
    ;;
    help|*) info "busybee tobs {install/uninstall} {NAMESPACE} {opt.FILEPATH}";;
  esac
}