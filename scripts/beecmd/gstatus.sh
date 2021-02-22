#!/bin/bash

## promql query
### 
status_promscale_instance='query=up{kubernetes_namespace="nexclipper",app="nc-promscale"}'
status_kube_api='query=up{job=~".*apiserver.*"}'
status_node_pod='query=sum(kube_pod_info) by (node) / sum(kube_node_status_allocatable_pods) by (node) * 100'
status_node_ready='query=kube_node_status_condition{condition="Ready",status="true"}'
status_node_mem='query=kube_node_status_condition{condition="MemoryPressure",status="true"}'
status_node_disk='query=kube_node_status_condition{condition="DiskPressure",status="true"}'
status_node_process='query=kube_node_status_condition{condition="PIDPressure",status="true"}'

## API list
#############################################
global_api(){
  status_node_process_va=`$curlcmd "${status_node_process}" $promsvr_DNS/api/v1/query \
  | jq '.data'`
  if [[ $status_node_process_va == "" ]]; then status_node_process_va="\""\"; fi

  status_promscale_instance_va=`$curlcmd "${status_promscale_instance}" $promsvr_DNS/api/v1/query \
  | jq '.data'`
  if [[ $status_promscale_instance_va == "" ]]; then status_promscale_instance_va="\""\"; fi

  status_kube_api_va=`$curlcmd "${status_kube_api}" $promsvr_DNS/api/v1/query \
  | jq '.data'`
  if [[ $status_kube_api_va == "" ]]; then status_kube_api_va="\""\"; fi
  
  status_node_ready_va=`$curlcmd "${status_node_ready}" $promsvr_DNS/api/v1/query \
  | jq '.data'`
  if [[ $status_node_ready_va == "" ]]; then status_node_ready_va="\""\"; fi

  status_node_mem_va=`$curlcmd "${status_node_mem}" $promsvr_DNS/api/v1/query \
  | jq '.data'`
  if [[ $status_node_mem_va == "" ]]; then status_node_mem_va="\""\"; fi

  status_node_disk_va=`$curlcmd "${status_node_disk}" $promsvr_DNS/api/v1/query \
  | jq '.data'`
  if [[ $status_node_disk_va == "" ]]; then status_node_disk_va="\""\"; fi

  status_node_pod_va=`$curlcmd "${status_node_pod}" $promsvr_DNS/api/v1/query \
  | jq '.data'`
  if [[ $status_node_pod_va == "" ]]; then status_node_pod_va="\""\"; fi

        wowjson=`cat << EOF
  {
    "k8sapi": "global-status",
    "data": {
      "lookup": [
        {
          "name": "status_promscale_instance",
          "type": "string",
          "values": $status_promscale_instance_va
        },
        {
          "name": "status_kube_api",
          "type": "string",
          "values": $status_kube_api_va
        },
        {
          "name": "status_node_pod",
          "type": "string",
          "values": $status_node_pod_va
        },
        {
          "name": "status_node_ready",
          "type": "string",
          "values": $status_node_ready_va
        },
        {
          "name": "status_node_mem",
          "type": "string",
          "values": $status_node_mem_va
        },
        {
          "name": "status_node_disk",
          "type": "string",
          "values": $status_node_disk_va
        },
        {
          "name": "status_node_process",
          "type": "string",
          "values": $status_node_process_va
        }
      ]
    }
  }
EOF
`            
      TOTAL_JSON=$(echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/ //g') 
      TYPE_JSON="base64"
      beejson
      #echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/\/ //g' -e 's/ //g' 
}

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
global_api
