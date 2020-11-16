#!/bin/bash
busybeecmd=$@
beecmdlog="/tmp/zzzbee"
echo $busybeecmd >> $beecmdlog
#beeA -> podsearch, beestatus, tobs etc
#beeB -> grafana, hello, etc..

provbeestatus(){
    case $beeB in
        hello) echo "hi" ;;
        help|*)  echo "busybee beestatus hello" ;;
    esac
}

nodesearch(){
    case $beeB in
        *)
            #NODEPORT=$(kubectl get svc -n $NAMESPACE -o jsonpath='{.items[?(@.metadata.name == "'$beecmd'")].spec.ports[0].nodePort}')
            NODEPORT=$(kubectl get svc -A -o jsonpath='{.items[?(@.metadata.name == "'$beeB'")].spec.ports[0].nodePort}')
            NODEOSIMAGE=$(kubectl get node -o jsonpath='{.items[*].status.nodeInfo.osImage}')
            if [[ $NODEPORT == "" ]]; then
                    echo "Not found K8s Service : $beeB"
                    exit 1
            else
                if [[ $NODEOSIMAGE == "Docker Desktop" ]]; then
                    echo "localhost:$NODEPORT"
                else
                    kubectl get nodes -o jsonpath='{range $.items[*]}{.status.addresses[?(@.type=="InternalIP")].address }{"':$NODEPORT'\n"}{end}'
                fi
            fi
            ;;
        help|HELP)  echo "busybee nodesearch {K8s Service}" ;;
    esac
#kubectl patch service -n tobs-tset nc-grafana -p '{\"spec\":{\"type\":\"NodePort\"}}'
#kubectl patch service -n tobs-tset nc-grafana --type='json' -p '[{"op":"replace","path":"/spec/type","value":"ClusterIP"},{"op":"replace","path":"/spec/ports/0/nodePort","value":null}]'
}

tobscmd(){
    #tobs $beecmd -n nc --namespace $beenamespace -f provbeetmp
    if [[ $beeC == "" ]]; then beeC="nexclipper"; fi
    if [[ $beeB == "passwd" ]]; then chpasswd="$beeD"; fi
    if [[ $beeD =~ ^NexClipper\..*$ ]]; then
        sed -i 's/\\n//g' /tmp/$beeD.base64
        base64 -d /tmp/$beeD.base64 > /tmp/$beeD
        filepath="-f /tmp/$beeD"
    fi
    case $beeB in
        install) 
            tobs install -n nc --namespace $beeC $filepath
        ############ tobs install chk start
            tobs_status=$(kubectl get pods -n $beeC 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l)
                sleep 3
            while [ $tobs_status != "0" ]; do
                tobszzz=$((tobszzz+1))
                tobs_status=$(kubectl get pods -n $beeC 2>/dev/null |grep -v NAME|grep nc-grafana|grep -E -v 'unning.|ompleted'|wc -l) 
                sleep 3
                if [ $tobszzz == "99" ]; then >&2 echo "tobs install checking time out(300s)" ; exit 1 ; fi
            done
        ######### tobs install chk stop
        ;;

        uninstall)
        tobs uninstall -n nc --namespace $beeC $filepath
        tobs helm delete-data -n nc --namespace $beeC
        ;;
        passwd)
        #pwchstatus=$(tobs -n nc --namespace $beeC grafana change-password $chpasswd 2>&1 |grep successfully | wc -l)
        tobs -n nc --namespace $beeC grafana change-password $chpasswd >/tmp/gra_pwd 2>&1
        pwchstatus=$(cat /tmp/gra_pwd |grep successfully | wc -l)
        if [ $pwchstatus -eq 1 ]; then echo "OK"
            sed -i "s/passwd $beeC $chpasswd.*/passwd $beeC :)/g" $beecmdlog
        else echo "FAIL"
            sed -i "s/passwd $beeC $chpasswd.*/passwd $beeC :(/g" $beecmdlog
        fi
        ;;
        help|*) echo "busybee tobs {install/uninstall} {NAMESPACE} {opt.FILEPATH}";;
    esac
}

k8s_api(){
    curlcmd="curl -sL -G --data-urlencode"
    promsvr_DNS="http://nc-prometheus-server.$beeC.svc.cluster.local"
    cluster_age(){
        cluster_age_va=`$curlcmd 'query=sum(time() - kube_service_created{namespace="default",service="kubernetes"})' $promsvr_DNS/api/v1/query \
        | jq '.data.result[].value[1]'`
        if [[ $cluster_age_va == "" ]]; then cluster_age_va="\""\"; fi
    }
    cluster_status(){
        cluster_status_va=`$curlcmd 'query=kube_node_status_condition{status="true",condition="Ready"}' $promsvr_DNS/api/v1/query \
        | jq '.data.result[].value[1]'`
        if [[ $cluster_status_va == "" ]]; then cluster_status_va="\""\"; fi
    }
    cluster_memory_use(){
        cluster_memory_use_va=`$curlcmd 'query=sum(container_memory_working_set_bytes{id="/"})/sum(machine_memory_bytes)*100' $promsvr_DNS/api/v1/query \
        | jq '.data.result[].value[1]'`
        if [[ $cluster_memory_use_va == "" ]]; then cluster_memory_use_va="\""\"; fi

    }
    cluster_cpu_use(){
        cluster_cpu_use_va=`$curlcmd 'query=sum(rate(container_cpu_usage_seconds_total{id="/"}[2m]))/sum(machine_cpu_cores)*100' $promsvr_DNS/api/v1/query \
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
        status_cluster_api_va=`$curlcmd 'query=up{job=~".*apiserver.*"}' $promsvr_DNS/api/v1/query \
        | jq '.data.result[].value[1]'`
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
        help|*) echo "Help me~~~~";;
    esac
}


p8s_api(){
    curlcmd="curl -sL -G --data-urlencode"
    promsvr_DNS="http://nc-prometheus-server.$beeC.svc.cluster.local"
    status_prometheus(){
        status_prometheus_va=`curl -sL -G -o /dev/null -w "%{http_code}"  $promsvr_DNS/-/healthy`
        if [[ $status_prometheus_va == "" ]]; then status_prometheus_va="\""\"; fi

    }
    cm_get(){
        if [[ $cm_target == "prom" ]]; then
                kubectl get configmap -n $beeC nc-prometheus-config -o json |jq '.data|{"data": .}'|base64 | tr '\n' ' ' | sed -e 's/ //g'
                #kubectl get configmap -n $beeC nc-prometheus-config -o json |jq '.data."prometheus.yml"'|base64 | tr '\n' ' ' | sed -e 's/ //g'
        elif [[ $cm_target == "alertm" ]]; then
                kubectl get configmap -n $beeC nc-prometheus-alertmanager -o json |jq '.data|{"data": .}'|base64 | tr '\n' ' ' | sed -e 's/ //g'
                #kubectl get configmap -n $beeC nc-prometheus-alertmanager -o json |jq '.data."alertmanager.yml"'|base64 | tr '\n' ' ' | sed -e 's/ //g'
        else
                echo "ang~"
        fi

    }
    cm_apply(){
        if [[ $p8sconfigfile =~ ^Nex-prom_config\..*$ ]]; then
            #sed -i 's/\\n//g' /tmp/$p8sconfigfile.base64
            #base64 -d /tmp/$p8sconfigfile.base64 > /tmp/$p8sconfigfile
            filepath="/tmp/$p8sconfigfile.base64"
        elif [[ $p8sconfigfile =~ ^Nex-alt_config\..*$ ]]; then
            #sed -i 's/\\n//g' /tmp/$p8sconfigfile.base64
            #base64 -d /tmp/$p8sconfigfile.base64 > /tmp/$p8sconfigfile
            filepath="/tmp/$p8sconfigfile.base64"
        else
            >&2 echo "file not found"
        fi

        if [[ $cm_target == "prom" ]]; then
                #echo $filepath
                cat $filepath > /tmp/rrrrrrrrr 
                #echo "kubectl patch configmaps -n $beeC nc-prometheus-config --patch "$(cat $filepath)""
                kubectl patch configmaps -n $beeC nc-prometheus-config --patch "$(cat $filepath|base64 -d|jq '{"data": {"prometheus.yml": .}}')"
        elif [[ $cm_target == "alertm" ]]; then
                #echo $filepath
                cat $filepath > /tmp/aaaaaaaaa 
                #echo "kubectl patch configmaps -n $beeC nc-prometheus-alertmanager --patch "$(cat $filepath)""
                kubectl patch configmaps -n $beeC nc-prometheus-alertmanager --patch "$(cat $filepath|base64 -d|jq '{"data": {"alertmanager.yml": .}}')"
        else
                echo "ang~"
        fi
    }

    ################ Case
    case $beeB in
        wow)
            status_prometheus
        wowjson=`cat << EOF
  {
    "k8sapi": "provbee-test",
    "data": {
      "lookup": [
        {
          "name": "status_prometheus",
          "type": "string",
          "values": "$status_prometheus_va"
        }
      ]
    }
  }
EOF
`            
        echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/ //g' 
        #echo $wowjson |base64 | tr '\n' ' ' | sed -e 's/\/ //g' -e 's/ //g' 
        ;;
        cm)
            while read LASTA LASTB LASTC; do
                case $LASTA in
                    prom|prometheus) cm_target="prom";;
                    alert|alertmanager) cm_target="alertm";;
                esac
                if [[ $LASTB != "" ]]; then p8sconfigfile=$LASTB; fi
            done < <(echo $beeLAST)
            case $beeD in
                    get) cm_get;;
                    apply) cm_apply;;
                    *) >&2 echo ">> p8s cm NAMESPACE get/apply prometheus/alertmanager" ;;
            esac
        ;;
        help|*) echo "Help me~~~~";;
    esac
}



while read beeA beeB beeC beeD beeLAST ; do
    case $beeA in
        ######### bee status check
        beestatus)  provbeestatus ;;

        ######### NodePort search
        nodesearch) nodesearch ;;

        ######### tobs command
        tobs)   tobscmd ;;

        ######### k8s API
        k8s)    k8s_api;;

        ######### p8s API
        p8s)    p8s_api;;

        ############## help
        help|*) echo "beestatus/nodesearch/tobs ...";;
    esac
done < <(echo $busybeecmd)

