#!/bin/bash
busybeecmd=$@

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
        install) tobs install -n nc --namespace $beeC $filepath;; 
        uninstall) 
        tobs uninstall -n nc --namespace $beeC $filepath
        tobs helm delete-data -n nc --namespace $beeC
        ;;
        passwd)
        pwchstatus=$(tobs -n nc --namespace $beeC grafana change-password $chpasswd 2>&1 |grep successfully | wc -l)
        if [ $pwchstatus -eq 1 ]; then echo "OK"; else echo "FAIL"; fi
        ;;
        help|*) echo "busybee tobs {install/uninstall} {NAMESPACE} {opt.FILEPATH}";;
    esac
}

k8s_api(){
    promsvr_DNS="http://nc-prometheus-server.$beeC.svc.cluster.local"
    case $beeB in
        cluster_age) 
        curl -sL -G --data-urlencode 'query=sum(time() - kube_service_created{namespace="default",service="kubernetes"})' $promsvr_DNS/api/v1/query ;;
        cluster_status) 
        curl -sL -G --data-urlencode 'query=kube_node_status_condition{status="true",condition="Ready"}' $promsvr_DNS/api/v1/query ;;
        cluster_memory_use) 
        curl -sL -G --data-urlencode 'query=sum(container_memory_working_set_bytes{id="/"})/sum(machine_memory_bytes)*100' $promsvr_DNS/api/v1/query ;;
        cluster_cpu_use) 
        curl -sL -G --data-urlencode 'query=sum(rate(container_cpu_usage_seconds_total{id="/"}[2m]))/sum(machine_cpu_cores)*100' $promsvr_DNS/api/v1/query ;;
        cluster_store_use) 
        curl -sL -G --data-urlencode 'query=sum (container_fs_usage_bytes{id="/"}) / sum (container_fs_limit_bytes{id="/"}) * 100' $promsvr_DNS/api/v1/query ;;
        cluster_pod_use) 
        curl -sL -G --data-urlencode 'query=sum(kube_pod_info) / sum(kube_node_status_allocatable_pods) * 100' $promsvr_DNS/api/v1/query ;;
        total_node) 
        curl -sL -G --data-urlencode 'query=sum(kube_node_info)' $promsvr_DNS/api/v1/query ;;
        total_unavail_node) 
        curl -sL -G --data-urlencode 'query=sum(kube_node_spec_unschedulable)' $promsvr_DNS/api/v1/query ;;
        total_namespace) 
        curl -sL -G --data-urlencode 'query=count(kube_namespace_created)' $promsvr_DNS/api/v1/query ;;
        total_pods) 
        curl -sL -G --data-urlencode 'query=count(kube_pod_info)' $promsvr_DNS/api/v1/query ;;
        count_restart_pod) 
        curl -sL -G --data-urlencode 'query=sum (kube_pod_status_phase{}) by (phase)' $promsvr_DNS/api/v1/query ;;
        count_failed_pod) 
        curl -sL -G --data-urlencode 'query=sum(kube_pod_status_phase{phase="Failed"})' $promsvr_DNS/api/v1/query ;;
        count_pending_pod) 
        curl -sL -G --data-urlencode 'query=sum(kube_pod_status_phase{phase="Pending"})' $promsvr_DNS/api/v1/query ;;
        total_pvcs) 
        curl -sL -G --data-urlencode 'query=count(kube_persistentvolumeclaim_info)' $promsvr_DNS/api/v1/query ;;
        status_prometheus) 
        curl -sL -G $promsvr_DNS/-/healthy;;
        status_alertmanager) 
        curl -sL -G "nc-prometheus-alertmanager.$beeC.svc.cluster.local/-/healthy";;
        status_cluster_api) 
        curl -sL -G --data-urlencode 'query=up{job=~".*apiserver.*"}' $promsvr_DNS/api/v1/query ;;
        rate_cluster_api) 
        curl -sL -G --data-urlencode 'query=sum by (code) (rate(apiserver_request_total[5m]))' $promsvr_DNS/api/v1/query ;;
        total_alerts) 
        curl -sL -G $promsvr_DNS/api/v1/alerts;;
        help|*) echo "DDDDDDDDD";;
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
        p8s)    echo "p8s";;
        
        ############## help
        help|*) echo "beestatus/nodesearch/tobs ...";;
    esac
done < <(echo $busybeecmd)
