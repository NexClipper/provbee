#!/bin/bash
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
if [[ $NEXNS == "" ]]; then NEXNS="nexclipper"; fi
###

#GoodBye!!
goodbye_provbee(){
  kubedel="kubectl delete -n "
  kubectl exec -it -n ${KUBENAMESPACE} deployment/provbee -- busybee tobs uninstall $NEXNS 2>/dev/null
  $kubedel ${KUBENAMESPACE} service/provbee-service 2>/dev/null
  $kubedel ${KUBENAMESPACE} deployment/provbee 2>/dev/null
  #kubectl get po -n ${KUBENAMESPACE} -o jsonpath='{range $.items[?(@.metadata.ownerReferences[*].name == "klevr-agent")]}{.metadata.name}{"\n"}{end}'| xargs kubectl delete -n ${KUBENAMESPACE} po
  #kubectl delete -n ${KUBENAMESPACE} po provbee
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
if [[ $DEL =~ ^([yY][eE][sS]|[yY])$ ]]; then goodbye_provbee ; fi
