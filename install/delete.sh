#!/bin/bash
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
if [[ $NEXNS == "" ]]; then NEXNS="nexclipper"; fi
###
zoneID_CHK(){
  ## Temporary information
  if [[ $CALLBACK == "" ]]; then goodbye_provbee; fi 
  ## ZoneID Chk
  zoneID_pod=$(kubectl get -n ${KUBENAMESPACE} daemonset/klevr-agent -o jsonpath='{.spec.template.spec.containers[*].env[?(@.name=="K_ZONE_ID")].value}')
  zoneID_call=$(echo $CALLBACK |base64 -d|awk -F"/" '{print $6}'|awk -F"?" '{print $1}')
  #### New #### zoneID_call=$(echo $CALLBACK |base64 -d|awk -F"/" '{print $7}'|awk -F"?" '{print $1}')
  if [[ $zoneID_pod == $zoneID_call ]]; then goodbye_provbee ; echo  ;else echo "Incorrect cluster information"; exit 1;fi 
}

#GoodBye!!
goodbye_provbee(){
ns_list=($KUBENAMESPACE $NEXNS)
for (( i = 0 ; i < ${#ns_list[@]}; i++ )); do
  kubectl get svc -n ${ns_list[$i]}|grep -v "NAME"|awk '{print $1}' | xargs kubectl delete -n ${ns_list[$i]} --force svc 2>/dev/null
  kubectl get deployment -n ${ns_list[$i]}|grep -v "NAME"|awk '{print $1}' | xargs kubectl delete -n ${ns_list[$i]} --force deployment 2>/dev/null
  kubectl get daemonset -n ${ns_list[$i]}|grep -v "NAME"|awk '{print $1}' | xargs kubectl delete -n ${ns_list[$i]} --force daemonset 2>/dev/null
  kubectl get pod -n ${ns_list[$i]}|grep -v "NAME"|awk '{print $1}' | xargs kubectl delete -n ${ns_list[$i]} --force pod 2>/dev/null
  kubectl get StatefulSet -n ${ns_list[$i]}|grep -v "NAME"|awk '{print $1}' | xargs kubectl delete -n ${ns_list[$i]} --force StatefulSet 2>/dev/null
  kubectl delete -n ${ns_list[$i]} clusterrolebinding ${KUBESERVICEACCOUNT}-rbac 2>/dev/null
  kubectl delete -n ${ns_list[$i]} secret ${KUBESERVICEACCOUNT}-secrets 2>/dev/null
  kubectl delete -n ${ns_list[$i]} configmap ${KUBENAMESPACE}-agent-config 2>/dev/null
  kubectl delete -n ${ns_list[$i]} role nexclipper-role 2>/dev/null
  kubectl delete -n ${ns_list[$i]} rolebinding ${KUBENAMESPACE}-rb 2>/dev/null
  kubectl delete -n ${ns_list[$i]} secret ${KUBESERVICEACCOUNT}-kubeconfig 2>/dev/null
  kubectl delete -n ${ns_list[$i]} secret ${KUBESERVICEACCOUNT}-ssh-key 2>/dev/null
  kubectl delete -n ${ns_list[$i]} sa ${KUBESERVICEACCOUNT} 2>/dev/null
  kubectl delete ns ${ns_list[$i]} 2>/dev/null
done
  chk1=$(kubectl get ns $NEXNS 2>/dev/null |wc -l)
  chk2=$(kubectl get ns $KUBENAMESPACE 2>/dev/null |wc -l)
  if [ $chk1 -eq 0 ] && [ $chk2 -eq 0 ]; then
    echo "Good Bye :'-( Beeeeeeeeeeeeeeeee 🐝"
    ## Temporary information
    if [[ $CALLBACK != "" ]]; then callback; fi 
  else
    echo "Check your NAMESPACE : $NEXNS, $KUBENAMESPACE "
    kubectl get ns
  fi
}
############ RUN CALLBACK
callback(){
  callurl=$(echo $CALLBACK|base64 -d)
  curl -sL -X DELETE $callurl > /tmp/provbee_bye.log
}
############ RUN CHK
if [[ $DEL =~ ^([yY][eE][sS]|[yY])$ ]]; then zoneID_CHK ; fi
