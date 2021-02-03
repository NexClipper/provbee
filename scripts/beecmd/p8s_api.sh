#!/bin/bash


#############################################
p8s_api(){
# PROVNS = nexclipper, provbeetmp = PROMCONFALY-YAML 
# ${beeCMD[4]} = $provbeetmp 
# ${beeCMD[3]} = recording_rules / alerting_rules / prometheus / alertmanager 
# ${beeCMD[2]} = get / test / apply
# ${beeCMD[1]} = nexclipper
# busybee p8s 0 1 2 3 4
# ############## cmd 0  1        2   3           4
# TEST : busybee p8s cm $PROVNS test $P8SCONF $provbeetmp
# GET : busybee p8s cm $PROVNS get $P8SCONF
# APPLY : busybee p8s cm $PROVNS apply $P8SCONF $provbeetmp 
# TOTAL : busybee p8s cm $PROVNS $GETCMD $GETCONFNAME $provbeetmp 

#############config map get, test, apply
  cm_get(){
    TOTAL_JSON=$(kubectl get configmap -n ${beeCMD[1]} $nc_configmap_name -o json |jq '.data|{"data": .}'|base64 | tr '\n' ' ' | sed -e 's/ //g')
      if [[ $TOTAL_JSON == "ewogICJkYXRhIjogbnVsbAp9Cg==" ]]; then STATUS_JSON="ERROR";fi
  }

  cm_test(){
    ## config file check
    if [ -f /tmp/$p8sconfigfile.base64 ]; then
      filepath="/tmp/$p8sconfigfile"
      cat $filepath.base64 | base64 -d | jq -r > $filepath.yaml
      ## yaml test
      nc_server=$(kubectl get pod -n ${beeCMD[1]} | grep $nc_svr_pod_name|awk '{print $1}')
      if [[ $nc_server == "" ]]; then fatal "Not found pod : $nc_svr_pod_name"; fi
      kubectl cp -n ${beeCMD[1]} $filepath.yaml $nc_server:$filepath.yaml -c $nc_svr_pod_in_name
      kubectl exec -i -n ${beeCMD[1]} $nc_server -c $nc_svr_pod_in_name -- $testtool_cmd $filepath.yaml > $filepath.status 2>&1
    else
      fatal "File not found : $p8sconfigfile.base64"
    fi
   
   
    if [ $(cat $filepath.status|grep FAILED|wc -l) == 0 ]; then
#      printf "OK"|base64 | tr '\n' ' ' | sed -e 's/ //g'
        TOTAL_JSON=$(echo "OK"|base64| tr '\n' ' ' | sed -e 's/ //g')
    else
#      cat $filepath.status|base64 | tr '\n' ' ' | sed -e 's/ //g'
        TOTAL_JSON=$(cat $filepath.status|base64 | tr '\n' ' ' | sed -e 's/ //g')
        STATUS_JSON="ERROR"
    fi
    ## yaml, base64 delete
    #rm -rf $filepath.base64 $filepath.yaml 
  }

  cm_apply(){
    ## config file check
    if [ -f /tmp/$p8sconfigfile.base64 ]; then
      filepath="/tmp/$p8sconfigfile"
      ## config file save
      kubectl patch configmaps -n ${beeCMD[1]} $nc_configmap_name --patch "$(cat $filepath.base64|base64 -d)" > $filepath.status 
      #kubectl patch configmaps -n ${beeCMD[1]} $nc_configmap_name --patch "$(cat $filepath.base64|base64 -d|jq '{"data": {"'"$cm_filename"'": .}}')" > $filepath.status
      ## config file apply
      #curl -sL -G -o /dev/null -w "%{http_code}" -X POST $dns_target/-/reload
      TOTAL_JSON=$(curl -sL -G -o /dev/null -w "%{http_code}" -X POST $dns_target/-/reload|base64| tr '\n' ' ' | sed -e 's/ //g')
    else
      fatal "file not found : $p8sconfigfile.base64"
    fi

    #rm -rf $filepath.base64
  }

  ################ Case
  case ${beeCMD[0]} in
    cm)
      case ${beeCMD[3]} in
        prometheus) 
          nc_svr_pod_name="nc-prometheus-server"
          nc_svr_pod_in_name="prometheus-server"
          nc_configmap_name="nc-prometheus-config"
#          cm_filename="prometheus.yml"
#          cm_target="prom"
          testtool_cmd="/bin/promtool check config"
          dns_target=$promsvr_DNS
        ;;
        alertmanager) 
          nc_svr_pod_name="nc-prometheus-alertmanager"
          nc_svr_pod_in_name="prometheus-alertmanager" 
          nc_configmap_name="nc-prometheus-alertmanager"
#          cm_filename="alertmanager.yml"
#          cm_target="alertm"
          testtool_cmd="/bin/amtool check-config"
          dns_target=$alertsvr_DNS
        ;;
        recording_rules|alerting_rules)
          nc_configmap_name="nc-prometheus-config"
          nc_svr_pod_name="nc-prometheus-server"
          nc_svr_pod_in_name="prometheus-server"      
          testtool_cmd="/bin/promtool check rules"
        ;;
      esac
      if [[ ${beeCMD[4]} != "" ]]; then p8sconfigfile=${beeCMD[4]}; fi
      case ${beeCMD[2]} in
        get) cm_get;;
        test) cm_test;;
        apply) cm_apply;;
        *) fatal ">> p8s cm NAMESPACE get/apply prometheus/alertmanager" ;;
      esac
    ;;
    help|*) info "Help me~~~~";;
  esac
}
# ${beeCMD[4]} = $provbeetmp 
# ${beeCMD[3]} = recording_rules / alerting_rules / prometheus / alertmanager 
# ${beeCMD[2]} = get / test / apply
# ${beeCMD[1]} = nexclipper
# busybee p8s cm 1 2 3 4
p8s_api
BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beetype\":\"base64\",\"data\":[\""${TOTAL_JSON}"\"]}]}"
echo $BEE_JSON