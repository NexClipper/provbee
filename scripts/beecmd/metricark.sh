#!/bin/bash
TYPE_JSON="base64"
STATUS_JSON="FAIL"
BEE_INFO="${beeCMD[0]}"
metricark_DNS="http://metricark-api.nex-system.svc.cluster.local:9000/v1/cluster/1/query/key/kubernetes/field"
#############################################
metricark_info(){
  #default query
  query_info(){
    query_json=`curl -sL -X GET --header 'Accept: application/json' $metricark_DNS/${beeCMD[0]}`
    if [ "$query_json" != "" ]; then STATUS_JSON="OK"
      else 
      TOTAL_JSON="No data" TYPE_JSON="string" 
      beejson;exit 0
    fi 
  }
  
  services_ark(){
    TOTAL_JSON=`echo $query_json |base64 | tr '\n' ' ' | sed -e 's/ //g'`
    beejson
  }

  nodes_ark(){
    query_length=`echo $query_json|jq '.data|keys|length'`
    if [ "$query_length" = "0" ]; then STATUS_JSON="FAIL";beejson;fi 
    jq_length=0
    while [ "$query_length" != "0" ];
    do
      nodes_value=`echo $query_json |jq ".data|keys|.[$jq_length]"`
      jq_query=".data."${nodes_value}"|{uid:.metadata.uid, name:.metadata.name, creationTimestamp: .metadata.creationTimestamp, addresses: .status.addresses, nodeInfo: .status.nodeInfo, capacity: .status.capacity}"
      nodes_info=`echo $query_json|jq -c "$jq_query"`
      nodes_json="{$nodes_value:$nodes_info}"
      jq_length=$((jq_length+1))
      nodes_json_total="${nodes_json_total}${nodes_json},"
      if [ $jq_length == $query_length ]; then query_length="0";fi
    done

    TOTAL_JSON=`echo "[${nodes_json_total%?}]" |base64 | tr '\n' ' ' | sed -e 's/ //g'`
    beejson

  }

    ################ Case
  case ${beeCMD[0]} in
    services) query_info; services_ark ;;   
    nodes) query_info; nodes_ark ;;
    pods) query_info;echo $query_json ;;
    help) fatal "Help me~~~~";;
    ${beeCMD[0]}) ${beeCMD[0]} > /dev/null 2>&1
      if [ "$(echo $next_json 2>&1 /dev/null |grep name)" != "" ];then echo ${next_json%?};exit 0;else STATUS_JSON="FAIL";TOTAL_JSON="Not Found query name : ${beeCMD[0]}";fi
      beejson
    ;;
  esac
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
metricark_info

