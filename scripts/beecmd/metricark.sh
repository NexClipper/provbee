#!/bin/bash
TYPE_JSON="base64"
STATUS_JSON="FAIL"
metricark_DNS="http://metricark-api.nex-system.svc.cluster.local:9000/v1/cluster/1/query/key/kubernetes/field"
curlcmd2="curl -sL -X GET --header 'Accept: application/json'"
#############################################
metricark_info(){
  #default query
  query_info(){
    query_json=`$curlcmd2 $metricark_DNS/${beeCMD[0]}`
    if [ "$query_json" != "" ]; then STATUS_JSON="OK";fi 
  }
  
  services_ark(){
    TOTAL_JSON=`echo $query_json |base64 | tr '\n' ' ' | sed -e 's/ //g'`
  }

  nodes_ark(){
    local api_query='query=sum(kube_node_status_condition{condition="Ready",status!="true"})'
    local query_name="cluster_status" 
    local query_value=`$curlcmd "${api_query}" $promsvr_DNS/api/v1/query \
    | jq '.data.result[].value[1]'`
    if [[ $query_value == "" ]]; then query_value="\""\"; fi
    local query_json="{\"name\":\"$query_name\",\"type\":\"string\",\"values\":$query_value},"
    next_json="${next_json}${query_json}"


    |jq '.items[].status.nodeInfo'
    |jq '.items[].metadata.labels'
    |jq '.items[].metadata.uid'
    |jq '.items[].metadata.creationTimestamp'

  }

    ################ Case
  case ${beeCMD[0]} in
#cat /usr/bin/beecmd/k8s_api.sh |grep "^  .*(){"
#egrep -v '^[[:space:]]*(#.*)?$'
    services)
      query_info 
      services_ark
      BEE_INFO="${beeCMD[0]}"
      #wowjson="{\"metricark\":[${next_json%?}]}"
      #TOTAL_JSON=$(echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/ //g') 
      ;;   
    nodes) echo "" ;;
    pods) echo "" ;;


      help) fatal "Help me~~~~";;
      ${beeCMD[0]}) ${beeCMD[0]} > /dev/null 2>&1
        if [ "$(echo $next_json 2>&1 /dev/null |grep name)" != "" ];then echo ${next_json%?};exit 0;else STATUS_JSON="FAIL";TOTAL_JSON="Not Found query name : ${beeCMD[0]}";fi
      ;;
    esac
}
metricark_info



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
beejson

