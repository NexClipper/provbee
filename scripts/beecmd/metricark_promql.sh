#!/bin/bash

TYPE_JSON="base64"
STATUS_JSON="FAIL"
#metricark_DNS="http://metricark-api.nex-system.svc.cluster.local:9000/v1/cluster/1/query/key/kubernetes/field"
metricark_promQL="http://metricark-api.nex-system.svc.cluster.local:9000/v1/p8s/query"
promQL=${beeCMD[0]}
p8sEP=${beeCMD[1]}
#############################################
metricark_promql(){
ql_string="promql=$promQL&endpoint=$p8sSVR"
STATUS_JSON="OK"
BEE_INFO="P8S Query"
TOTAL_JSON=$(curl -sL "${metricark_promQL}?$ql_string"|base64| tr '\n' ' ' | sed -e 's/ //g')
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