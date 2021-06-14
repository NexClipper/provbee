#!/bin/bash

## promql query
### 

## API list
#############################################
global_api(){
  status_promscale_instance(){
    local api_query='query=up{kubernetes_namespace="nexclipper",app="nc-promscale"}'
    local query_name="status_promscale_instance"
    local query_value=`$curlcmd "${api_query}" $promscale_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  status_kube_api(){
    local api_query='query=up{job=~".*apiserver.*"}'
    local query_name="status_kube_api"
    local query_value=`$curlcmd "${api_query}" $promscale_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  status_node_pod(){
    local api_query='query=sum(kube_pod_info) by (node) / sum(kube_node_status_allocatable_pods) by (node) * 100'
    local query_name="status_node_pod"
    local query_value=`$curlcmd "${api_query}" $promscale_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  status_node_ready(){
    local api_query='query=kube_node_status_condition{condition="Ready",status="true"}'
    local query_name="status_node_ready"
    local query_value=`$curlcmd "${api_query}" $promscale_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  status_node_mem(){
    local api_query='query=kube_node_status_condition{condition="MemoryPressure",status="true"}'
    local query_name="status_node_mem"
    local query_value=`$curlcmd "${api_query}" $promscale_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  status_node_disk(){
    local api_query='query=kube_node_status_condition{condition="DiskPressure",status="true"}'
    local query_name="status_node_disk"
    local query_value=`$curlcmd "${api_query}" $promscale_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  status_node_process(){
    local api_query='query=kube_node_status_condition{condition="PIDPressure",status="true"}'
    local query_name="status_node_process"
    local query_value=`$curlcmd "${api_query}" $promscale_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
status_promscale_instance
status_kube_api
status_node_pod
status_node_ready
status_node_mem
status_node_disk
status_node_process
  wowjson="{\"k8sapi\":\"global-status\",\"data\":{\"lookup\":[${next_json%?}]}}"
  #wowjson="{\"k8s_status\":[${next_json%?}]}"
  TOTAL_JSON=$(echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/ //g') 
  TYPE_JSON="base64"
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
global_api
