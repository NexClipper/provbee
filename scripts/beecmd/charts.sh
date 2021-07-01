#!/bin/bash
chartslog="/tmp/busybee_charts_$(date "+%Y%m%d_%H%M%S").log"
NEX_CHART="https://nexclipper.github.io/helm-charts/"

#busybee charts install(0)  $GET_NS(1)  $GET_APP(2) $GET_TMP(3) $GET_TYPE(4)
#busybee charts install     nexclipper  mysql Nex_charts.ddddd mysql-exporter              
#############################################
chartscmd(){
  case ${beeCMD[0]} in
  install) 
    ## install value file decoding
    sed -i 's/\\n//g' /tmp/${beeCMD[3]}.base64; base64 -d /tmp/${beeCMD[3]}.base64 > /tmp/${beeCMD[3]}.yaml; filepath="-f /tmp/${beeCMD[3]}.yaml"
    helm_repo_add=`helm repo add ${beeCMD[1]} $NEX_CHARTS 2>&1`
    helm_repo_up=`helm repo update 2>&1`
    helm_inst=`helm install ${beeCMD[2]} -n ${beeCMD[1]} ${filepath} ${beeCMD[4]} 2>&1`
    if [ "$(echo $helm_inst | egrep "^Error")" = "" ]; then 
      TYPE_JSON="json"
      BEE_INFO="Helm ${beeCMD[0]} info : ${beeCMD[2]}"
      TOTAL_JSON=`helm list -n ${beeCMD[1]} --filter "^${beeCMD[2]}$" -o json 2>&1`
      beejson
    else
      STATUS_JSON="FAIL"
      TYPE_JSON="string"
      BEE_INFO="Helm ${beeCMD[0]} Fail Log"
      TOTAL_JSON=$(echo $helm_inst)
      beejson
    fi
  ;;
  update) echo "";;
  uninstall) 
    TYPE_JSON="string"
    helm_uninst=`helm uninstall ${beeCMD[2]} -n ${beeCMD[1]} 2>&1`
    if [ "$(echo $helm_uninst | egrep "^Error")" = "" ]; then
      BEE_INFO="Helm ${beeCMD[0]} info : ${beeCMD[2]}"
      TOTAL_JSON="${beeCMD[2]} uninstalled"
      beejson
    else
      STATUS_JSON="FAIL"
      BEE_INFO="Helm ${beeCMD[0]} Fail Log"
      TOTAL_JSON=$(echo $helm_uninst)
      beejson
    fi
  ;;
  list)
    TYPE_JSON="json"
    BEE_INFO="Helm ${beeCMD[0]} info : ${beeCMD[2]}"
    TOTAL_JSON=`helm list -n ${beeCMD[1]} --filter "^${beeCMD[2]}$" -o json 2>&1`
    if [ "$(echo $TOTAL_JSON | egrep -v "\[\]")" = "" ]; then STATUS_JSON="FAIL";fi 
    beejson 
  ;;
  *) echo "";;
  esac
}

beejson(){
#### Print JSON
if [[ $TYPE_JSON == "json" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[${TOTAL_JSON}]}]}"
elif [[ $TYPE_JSON == "base64" ]] || [[ $TYPE_JSON == "string" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}]}"
else
  BEE_JSON="Bee!"
fi
echo $BEE_JSON
}

chartscmd