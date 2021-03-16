#!/bin/bash
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
if [[ $NEXNS == "" ]]; then NEXNS="nexclipper"; fi
###

#GoodBye!!
goodbye_provbee(){
  kubedel="kubectl delete -n "
  kubectl exec -it -n ${KUBENAMESPACE} deployment/provbee -- busybee tobs uninstall $NEXNS
  kubectl delete ns $NEXNS
  $kubedel -n ${KUBENAMESPACE} service/provbee-service
  $kubedel -n ${KUBENAMESPACE} deployment/provbee
  #kubectl get po -n ${KUBENAMESPACE} -o jsonpath='{range $.items[?(@.metadata.ownerReferences[*].name == "klevr-agent")]}{.metadata.name}{"\n"}{end}'| xargs kubectl delete -n ${KUBENAMESPACE} po
  #kubectl delete -n ${KUBENAMESPACE} po provbee
  $kubedel -n ${KUBENAMESPACE} daemonset/klevr-agent
  $kubedel -n ${KUBENAMESPACE} clusterrolebinding ${KUBESERVICEACCOUNT}-rbac
  $kubedel -n ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-secrets
  $kubedel -n ${KUBENAMESPACE} configmap ${KUBENAMESPACE}-agent-config
  $kubedel -n ${KUBENAMESPACE} role nexclipper-role
  $kubedel -n ${KUBENAMESPACE} rolebinding ${KUBENAMESPACE}-rb
  $kubedel -n ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-kubeconfig
  $kubedel -n ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-ssh-key
  $kubedel -n ${KUBENAMESPACE} sa ${KUBESERVICEACCOUNT}
  $kubedel ns ${KUBENAMESPACE}
}


############ RUN CHK
if [[ $DEL =~ ^([yY][eE][sS]|[yY])$ ]]; then goodbye_provbee ; fi
