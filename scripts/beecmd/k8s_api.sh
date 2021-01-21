k8s_api(){
  cluster_age(){
    cluster_age_va=`$curlcmd 'query=sum(time() - kube_service_created{namespace="default",service="kubernetes"})' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $cluster_age_va == "" ]]; then cluster_age_va="\""\"; fi
  }
  cluster_status(){
    #cluster_status_va=`$curlcmd 'query=kube_node_status_condition{status="true",condition="Ready"}' $promsvr_DNS/api/v1/query \
    cluster_status_va=`$curlcmd 'query=sum(kube_node_status_condition{condition="Ready",status!="true"})' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $cluster_status_va == "" ]]; then cluster_status_va="\""\"; fi
  }
  cluster_memory_use(){
    #cluster_memory_use_va=`$curlcmd 'query=sum(container_memory_working_set_bytes{id="/"})/sum(machine_memory_bytes)*100' $promsvr_DNS/api/v1/query \
    #cluster_memory_use_va=`$curlcmd 'query=sum(container_memory_usage_bytes{pod!="POD",namespace!=""})/sum(kube_node_status_capacity{resource="memory"})*100' $promsvr_DNS/api/v1/query \
    cluster_memory_use_va=`$curlcmd 'query=(1-(sum(node_memory_MemAvailable_bytes)/sum(node_memory_MemTotal_bytes)))*100' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $cluster_memory_use_va == "" ]]; then cluster_memory_use_va="\""\"; fi
  }
  cluster_cpu_use(){
    #cluster_cpu_use_va=`$curlcmd 'query=sum(rate(container_cpu_usage_seconds_total{id="/"}[2m]))/sum(machine_cpu_cores)*100' $promsvr_DNS/api/v1/query \
    cluster_cpu_use_va=`$curlcmd 'query=sum(rate(container_cpu_usage_seconds_total{id="/"}[2m]))/count(node_cpu_seconds_total{mode="idle"})*100' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $cluster_cpu_use_va == "" ]]; then cluster_cpu_use_va="\""\"; fi
  }
  cluster_store_use(){
    cluster_store_use_va=`$curlcmd 'query=sum (container_fs_usage_bytes{id="/"}) / sum (container_fs_limit_bytes{id="/"}) * 100' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $cluster_store_use_va == "" ]]; then cluster_store_use_va="\""\"; fi
  }
  cluster_pod_use(){
    cluster_pod_use_va=`$curlcmd 'query=sum(kube_pod_info) / sum(kube_node_status_allocatable_pods) * 100' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $cluster_pod_use_va == "" ]]; then cluster_pod_use_va="\""\"; fi
  }
  total_node(){
    total_node_va=`$curlcmd 'query=sum(kube_node_info)' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $total_node_va == "" ]]; then total_node_va="\""\"; fi
  }
  total_unavail_node(){
    total_unavail_node_va=`$curlcmd 'query=sum(kube_node_spec_unschedulable)' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $total_unavail_node_va == "" ]]; then total_unavail_node_va="\""\"; fi
  }
  total_namespace(){
    total_namespace_va=`$curlcmd 'query=count(kube_namespace_created)' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $total_namespace_va == "" ]]; then total_namespace_va="\""\"; fi
  }
  total_pods(){
    total_pods_va=`$curlcmd 'query=count(kube_pod_info)' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $total_pods_va == "" ]]; then total_pods_va="\""\"; fi
  }
  count_restart_pod(){
    count_restart_pod_va=`$curlcmd 'query=count(sum by (pod)(delta(kube_pod_container_status_restarts_total[30m]) > 0))' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $count_restart_pod_va == "" ]]; then count_restart_pod_va="\""\"; fi
  }
  count_failed_pod(){
    count_failed_pod_va=`$curlcmd 'query=sum(kube_pod_status_phase{phase="Failed"})' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $count_failed_pod_va == "" ]]; then count_failed_pod_va="\""\"; fi
  }
  count_pending_pod(){
    count_pending_pod_va=`$curlcmd 'query=sum(kube_pod_status_phase{phase="Pending"})' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $count_pending_pod_va == "" ]]; then count_pending_pod_va="\""\"; fi
  }
  total_pvcs(){
    total_pvcs_va=`$curlcmd 'query=count(kube_persistentvolumeclaim_info)' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $total_pvcs_va == "" ]]; then total_pvcs_va="\""\"; fi
  }
  status_prometheus(){
    status_prometheus_va=`curl -sL -G -o /dev/null -w "%{http_code}"  $promsvr_DNS/-/healthy`
    if [[ $status_prometheus_va == "" ]]; then status_prometheus_va="\""\"; fi
  }
  status_alertmanager(){
    status_alertmanager_va=`curl -sL -G -o /dev/null -w "%{http_code}" "nc-prometheus-alertmanager.$beeC.svc.cluster.local/-/healthy"`
    if [[ $status_alertmanager_va == "" ]]; then status_alertmanager_va="\""\"; fi
  }
  status_cluster_api(){
    status_cluster_api_va=`$curlcmd 'query=sum(up{job=~".*apiserver.*"})/count(up{job=~".*apiserver.*"}) > bool 0' $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    #status_cluster_api_va=`$curlcmd 'query=up{job=~".*apiserver.*"}' $promsvr_DNS/api/v1/query \
    if [[ $status_cluster_api_va == "" ]]; then status_cluster_api_va="\""\"; fi
  }
  rate_cluster_api(){
    rate_cluster_api_va=`$curlcmd 'query=sum by (code) (rate(apiserver_request_total[5m]))' $promsvr_DNS/api/v1/query \
    | jq '.data'`
    #| jq '.data.result[]'`
    #| jq '.data.result[]' |base64 | tr '\n' ' ' | sed -e 's/\/ //g' -e 's/ //g'
    if [[ $rate_cluster_api_va == "" ]]; then rate_cluster_api_va="\""\"; fi
  }
  total_alerts(){
      total_alerts_va=`curl -sL -G $promsvr_DNS/api/v1/alerts \
      | jq '.data'`
      #| jq '.data.alerts[]| {"status": .status}'`
      #| jq '.data.alerts[]| {"status": .status}' |base64 | tr '\n' ' ' | sed -e 's/\/ //g' -e 's/ //g'
      if [[ $total_alerts_va == "" ]]; then total_alerts_va="\""\"; fi

  }

    ################ Case
    case $beeB in
#        cluster_age) cluster_age ;;
#        cluster_status) cluster_status ;;
#        cluster_memory_use) cluster_memory_use ;;
#        cluster_cpu_use) cluster_cpu_use ;;
#        cluster_store_use) cluster_store_use ;;
#        cluster_pod_use) cluster_pod_use ;;
#        total_node) total_node ;;
#        total_unavail_node) total_unavail_node ;;
#        total_namespace) total_namespace ;;
#        total_pods) total_pods ;;
#        count_restart_pod) count_restart_pod ;;
#        count_failed_pod) count_failed_pod ;;
#        count_pending_pod) count_pending_pod ;;
#        total_pvcs) total_pvcs ;;
#        status_prometheus) status_prometheus ;;
#        status_alertmanager) status_alertmanager ;;
#        status_cluster_api) status_cluster_api ;;
#        rate_cluster_api) rate_cluster_api ;;
#        total_alerts) total_alerts ;;
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

        wowjson=`cat << EOF
  {
    "k8sapi": "provbee-test",
    "data": {
      "lookup": [
        {
          "name": "cluster_age",
          "type": "string",
          "values": $cluster_age_va
        },
        {
          "name": "cluster_status",
          "type": "string",
          "values": $cluster_status_va
        },
        {
          "name": "cluster_memory_use",
          "type": "string",
          "values": $cluster_memory_use_va
        },
        {
          "name": "cluster_cpu_use",
          "type": "string",
          "values": $cluster_cpu_use_va
        },
        {
          "name": "cluster_store_use",
          "type": "string",
          "values": $cluster_store_use_va
        },
        {
          "name": "cluster_pod_use",
          "type": "string",
          "values": $cluster_pod_use_va
        },
        {
          "name": "total_node",
          "type": "string",
          "values": $total_node_va
        },
        {
          "name": "total_unavail_node",
          "type": "string",
          "values": $total_unavail_node_va
        },
        {
          "name": "total_namespace",
          "type": "string",
          "values": $total_namespace_va
        },
        {
          "name": "total_pods",
          "type": "string",
          "values": $total_pods_va
        },
        {
          "name": "count_restart_pod",
          "type": "string",
          "values": $count_restart_pod_va
        },
        {
          "name": "count_failed_pod",
          "type": "string",
          "values": $count_failed_pod_va
        },
        {
          "name": "count_pending_pod",
          "type": "string",
          "values": $count_pending_pod_va
        },
        {
          "name": "total_pvcs",
          "type": "string",
          "values": $total_pvcs_va
        },
        {
          "name": "status_prometheus",
          "type": "string",
          "values": "$status_prometheus_va"
        },
        {
          "name": "status_alertmanager",
          "type": "string",
          "values": "$status_alertmanager_va"
        },
        {
          "name": "status_cluster_api",
          "type": "string",
          "values": $status_cluster_api_va
        },
        {
          "name": "rate_cluster_api",
          "type": "string",
          "values": $rate_cluster_api_va
        },
        {
          "name": "total_alerts",
          "type": "string",
          "values": $total_alerts_va
        }
      ]
    }
  }
EOF
`            
      echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/ //g' 
      #echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/\/ //g' -e 's/ //g' 
      ;;
      help|*) info "Help me~~~~";;
    esac
}
