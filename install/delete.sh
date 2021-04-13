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
  #zoneID_call=$(echo $CALLBACK |base64 -d|awk -F"/|?" '{print $6}')
  zoneID_call=$(echo $CALLBACK ||base64 -d|awk -F"/" '{print $6}'|awk -F"?" '{print $1}')
  if [[ $zoneID_pod == $zoneID_call ]]; then goodbye_provbee ; echo  ;else echo "Incorrect cluster information"; exit 1;fi 
}


#GoodBye!!
goodbye_provbee(){
  kubedel="kubectl delete -n "
  kubectl exec -it -n ${KUBENAMESPACE} deployment/provbee -- busybee tobs uninstall $NEXNS 2>/dev/null
  $kubedel ${KUBENAMESPACE} service/provbee-service 2>/dev/null
  $kubedel ${KUBENAMESPACE} deployment/provbee 2>/dev/null
  $kubedel ${KUBENAMESPACE} daemonset/klevr-agent 2>/dev/null
  $kubedel ${KUBENAMESPACE} clusterrolebinding ${KUBESERVICEACCOUNT}-rbac 2>/dev/null
  $kubedel ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-secrets 2>/dev/null
  $kubedel ${KUBENAMESPACE} configmap ${KUBENAMESPACE}-agent-config 2>/dev/null
  $kubedel ${KUBENAMESPACE} role nexclipper-role 2>/dev/null
  $kubedel ${KUBENAMESPACE} rolebinding ${KUBENAMESPACE}-rb 2>/dev/null
  $kubedel ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-kubeconfig 2>/dev/null
  $kubedel ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-ssh-key 2>/dev/null
  $kubedel ${KUBENAMESPACE} sa ${KUBESERVICEACCOUNT} 2>/dev/null
  kubectl delete ns $NEXNS 2>/dev/null
  kubectl delete ns ${KUBENAMESPACE} 2>/dev/null
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
