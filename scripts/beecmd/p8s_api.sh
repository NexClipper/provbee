#!/bin/bash


#############################################
p8s_api(){
#  p8setc_status(){  
#   status_prometheus_va=`curl -sL -G -o /dev/null -w "%{http_code}"  $promsvr_DNS/-/healthy`
#   if [[ $status_prometheus_va == "" ]]; then status_prometheus_va="\""\"; fi
#   status_alertmanager_va=`curl -sL -G -o /dev/null -w "%{http_code}"  $alertsvr_DNS/-/healthy`
#   if [[ $status_alertmanager_va == "" ]]; then status_alertmanager_va="\""\"; fi
#  }

#############config map get, test, apply
  cm_get(){
    kubectl get configmap -n ${beeCMD[1]} $nc_configmap_name -o json |jq '.data|{"data": .}'|base64 | tr '\n' ' ' | sed -e 's/ //g'
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
      printf "OK"|base64 | tr '\n' ' ' | sed -e 's/ //g'
    else
      cat $filepath.status|base64 | tr '\n' ' ' | sed -e 's/ //g'
    fi
    ## yaml, base64 delete 
    rm -rf $filepath.base64 $filepath.yaml 
  }

  cm_apply(){
    ## config file check
    if [ -f /tmp/$p8sconfigfile.base64 ]; then
      filepath="/tmp/$p8sconfigfile"
      ## config file save
      kubectl patch configmaps -n ${beeCMD[1]} $nc_configmap_name --patch "$(cat $filepath.base64|base64 -d|jq '{"data": {"'"$cm_filename"'": .}}')" > $filepath.status
      ## config file apply
      curl -sL -G -o /dev/null -w "%{http_code}" -X POST $dns_target/-/reload
    else
      fatal "file not found : $p8sconfigfile.base64"
    fi

    rm -rf $filepath.base64
  }

  ################ Case
  case ${beeCMD[0]} in
    cm)
        case ${beeCMD[3]} in
          prom|prometheus) 
            nc_svr_pod_name="nc-prometheus-server"
            nc_svr_pod_in_name="prometheus-server"
            nc_configmap_name="nc-prometheus-config"
            cm_filename="prometheus.yml"
            cm_target="prom"
            testtool_cmd="/bin/promtool check config"
            dns_target=$promsvr_DNS
          ;;
          alert|alertmanager) 
            nc_svr_pod_name="nc-prometheus-alertmanager"
            nc_svr_pod_in_name="prometheus-alertmanager" 
            nc_configmap_name="nc-prometheus-alertmanager"
            cm_filename="alertmanager.yml"
            cm_target="alertm"
            testtool_cmd="/bin/amtool check-config"
            dns_target=$alertsvr_DNS
          ;;
        esac
      if [[ ${beeCMD[4]} != "" ]]; then p8sconfigfile=${beeCMD[4]}; fi
        case ${beeCMD[2} in
          get) cm_get;;
          test) cm_test;;
          apply) cm_apply;;
          *) warn ">> p8s cm NAMESPACE get/apply prometheus/alertmanager" ;;
        esac
    ;;
    help|*) info "Help me~~~~";;
  esac
}
