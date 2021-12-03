#!/bin/bash

TYPE_JSON="base64"
#metricark_DNS="http://metricark-api.nex-system.svc.cluster.local:9000/v1/cluster/1/query/key/kubernetes/field"
metricark_promQL="http://metricark-api.nex-system.svc.cluster.local:9000/v1/p8s/query"
promQL=${beeCMD[0]}
p8sEP=${beeCMD[1]}
#############################################
metricark_promql(){
ql_string="promql=$promQL&endpoint=$p8sEP"
BEE_INFO="P8S Query"
query_value=$(curl -sL "${metricark_promQL}?$ql_string")
if [ $(echo $query_value|jq '.response_code') -eq 200 ]; then
  STATUS_JSON="OK"
  TOTAL_JSON=$(echo $query_value|base64| tr '\n' ' ' | sed -e 's/ //g')
else
  STATUS_JSON="FAIL"
  TOTAL_JSON=$(echo $query_value|base64| tr '\n' ' ' | sed -e 's/ //g')
fi
beejson
}

################Print JSON
beejson(){
if [[ $TYPE_JSON == "json" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[${TOTAL_JSON}]}]}"
elif [[ $TYPE_JSON == "base64" ]] || [[ $TYPE_JSON == "string" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}]}"
else
  BEE_JSON="Bee!"
fi
echo $BEE_JSON
}
metricark_promql
