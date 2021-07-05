#!/bin/bash


#############################################
k8s_status(){
  cluster_age(){
    local api_query='query=sum(time() - kube_service_created{namespace="default",service="kubernetes"})'
    local query_name="cluster_age" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  cluster_status(){
    local api_query='query=sum(kube_node_status_condition{condition="Ready",status!="true"})'
    local query_name="cluster_status" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  cluster_memory_use(){
    local api_query='query=(1-(sum(node_memory_MemAvailable_bytes)/sum(node_memory_MemTotal_bytes)))*100'
    local query_name="cluster_memory_use" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  cluster_cpu_use(){
    local api_query='query=sum(rate(container_cpu_usage_seconds_total{id="/"}[2m]))/count(node_cpu_seconds_total{mode="idle"})*100'
    local query_name="cluster_cpu_use" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  cluster_store_use(){
    local api_query='query=sum (container_fs_usage_bytes{id="/"}) / sum (container_fs_limit_bytes{id="/"}) * 100'
    local query_name="cluster_store_use" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  cluster_pod_use(){
    local api_query='query=sum(kube_pod_info) / sum(kube_node_status_allocatable_pods) * 100'
    local query_name="cluster_pod_use" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  total_node(){
    local api_query='query=sum(kube_node_info)'
    local query_name="total_node" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  total_unavail_node(){
    local api_query='query=sum(kube_node_spec_unschedulable)'
    local query_name="total_unavail_node" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  total_namespace(){
    local api_query='query=count(kube_namespace_created)'
    local query_name="total_namespace" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  total_pods(){
    local api_query='query=count(kube_pod_info)'
    local query_name="total_pods" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  count_restart_pod(){
    local api_query='query=count(sum by (pod)(delta(kube_pod_container_status_restarts_total[30m]) > 0))'
    local query_name="count_restart_pod" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  count_failed_pod(){
    local api_query='query=sum(kube_pod_status_phase{phase="Failed"})'
    local query_name="count_failed_pod" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  count_pending_pod(){
    local api_query='query=sum(kube_pod_status_phase{phase="Pending"})'
    local query_name="count_pending_pod" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  total_pvcs(){
    local api_query='query=count(kube_persistentvolumeclaim_info)'
    local query_name="total_pvcs" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  status_prometheus(){
    local query_name="status_prometheus"
    local query_value=`curl -sL -G -o /dev/null -w "%{http_code}"  $promsvr_DNS/-/healthy`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}" 
  }
  status_alertmanager(){
    local query_name="status_alertmanager" 
    local query_value=`curl -sL -G -o /dev/null -w "%{http_code}" $alertsvr_DNS/-/healthy`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}" 
  }
  status_cluster_api(){
    local api_query='query=sum(up{job=~".*apiserver.*"})/count(up{job=~".*apiserver.*"}) > bool 0'
    local query_name="status_cluster_api" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  rate_cluster_api(){
    local api_query='query=sum by (code) (rate(apiserver_request_total[5m]))'
    local query_name="rate_cluster_api" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  total_alerts(){
    local query_name="total_alerts" 
    local query_value=`curl -sL -G $promsvr_DNS/api/v1/alerts \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  stats_capacity(){
    local api_query='query=kubelet_volume_stats_capacity_bytes{namespace="nexclipper"}'
    local query_name="stats_capacity" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  stats_used(){
    local api_query='query=kubelet_volume_stats_capacity_bytes{namespace="nexclipper"} - kubelet_volume_stats_available_bytes{namespace="nexclipper"}'
    local query_name="stats_used"
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }
  stats_usage(){
    local api_query='query=(kubelet_volume_stats_capacity_bytes{namespace="nexclipper"} - kubelet_volume_stats_available_bytes{namespace="nexclipper"})/kubelet_volume_stats_capacity_bytes{namespace="nexclipper"}*100'
    local query_name="stats_usage"
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"
  }

    ################ Case
  case ${beeCMD[0]} in
#cat /usr/bin/beecmd/k8s_api.sh |grep "^  .*(){"
#egrep -v '^[[:space:]]*(#.*)?$'
    wow)
      cluster_age
      cluster_status
      cluster_memory_use
      cluster_cpu_use
      cluster_store_use
      cluster_pod_use
      total_node
      total_unavail_node
      total_namespace
      total_pods
      count_restart_pod
      count_failed_pod
      count_pending_pod
      total_pvcs
      status_prometheus
      status_alertmanager
      status_cluster_api
      rate_cluster_api
      total_alerts
      stats_capacity
      stats_used
      stats_usage
      #wowjson="{\"k8sapi\":\"provbee-test\",\"data\":{\"lookup\":[${next_json%?}]}}"
      wowjson="{\"k8s_status\":[${next_json%?}]}"
##### TEST RUN
#      test_json="{\"k8s_status\":[${next_json%?}]}"
#     echo $test_json |jq
##### TEST END
        TOTAL_JSON=$(echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/ //g') 
        TYPE_JSON="base64"
        BEE_INFO="k8s_status"
      ;;
      help) fatal "Help me~~~~";;
      ${beeCMD[0]}) ${beeCMD[0]} > /dev/null 2>&1
        if [ "$(echo $next_json 2>&1 /dev/null |grep name)" != "" ];then echo ${next_json%?};exit 0;else STATUS_JSON="FAIL";TOTAL_JSON="Not Found query name : ${beeCMD[0]}";fi
      ;;
    esac
}
k8s_status

metricark_api(){
local BEE_INFO="metricark"
local TYPE_JSON="base64" 
local TOTAL_JSON=$(curl -sL -X GET --header 'Accept: application/json' 'http://metricark-api.nex-system.svc.cluster.local:9000/v1/cluster/1/query/key/kubernetes/field/services'|base64 | tr '\n' ' ' | sed -e 's/ //g')
local STATUS_JSON="OK"
XXX=",{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}"
##### TEST RUN
#echo ${XXX#?}|jq 
}
metricark_api


################Print JSON
beejson(){
if [[ $TYPE_JSON == "json" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[${TOTAL_JSON}]}]}"
elif [[ $TYPE_JSON == "base64" ]] || [[ $TYPE_JSON == "string" ]]; then
  #BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}]}"
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}${XXX}]}"
else
  BEE_JSON="Bee!"
fi
echo $BEE_JSON |jq
}
beejson

