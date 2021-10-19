#!/bin/bash

TYPE_JSON="base64"
metricark_openstack_nodes="http://metricark-api.nex-system.svc.cluster.local:9000/v1/nodes"
projectName=${beeCMD[0]}
domainId=${beeCMD[1]}
#############################################
metricark_OpenstackNodes(){
ql_string="projectName=$projectName&domainId=$domainId"
BEE_INFO="Openstack Nodes"
query_value=$(curl -sL "${metricark_openstack_nodes}?$ql_string")
echo $query_value
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
metricark_OpenstackNodes