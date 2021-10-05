#!/bin/bash
TYPE_JSON="base64"

grafana_api(){
grafana_uri="nc-grafana.$runbeeNS.svc.cluster.local"
grafana_user="admin"
grafana_pwd=$(tobs -n nc --namespace $runbeeNS grafana get-password)
grafana_json=/tmp/grafana.json
if [ "${beeCMD[2]}" = "" ]; then STATUS_JSON="FAIL";BEE_INFO="json not found";beejson;exit 0;fi
echo ${beeCMD[2]}|base64 -d > $grafana_json
#sed -i 's/\\n//g' /tmp/${beeCMD[2]}.base64; base64 -d /tmp/${beeCMD[2]}.base64 > /tmp/${beeCMD[2]}; filepath="-f /tmp/${beeCMD[2]}"
run_value=$(curl -sL -X POST -H "Accept: application/json" -H "Content-Type: application/json" -d "@${grafana_json}" "${grafana_user}:${grafana_pwd}@${grafana_uri}/api/dashboards/db")
if [ "$(echo $run_value|jq -r '.status')" != "success" ]; then STATUS_JSON="FAIL";fi
TOTAL_JSON=$(echo $run_value|base64 | tr '\n' ' ' | sed -e 's/ //g')
beejson
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
grafana_api