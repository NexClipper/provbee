#!/bin/bash
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
if [[ $NEXNS == "" ]]; then NEXNS="nexclipper"; fi
###

#GoodBye!!
goodbye_provbee(){
  kubedel="kubectl delete -n "
  kubectl exec -it -n ${KUBENAMESPACE} deployment/provbee -- busybee tobs uninstall $NEXNS
  $kubedel ${KUBENAMESPACE} service/provbee-service
  $kubedel ${KUBENAMESPACE} deployment/provbee
  #kubectl get po -n ${KUBENAMESPACE} -o jsonpath='{range $.items[?(@.metadata.ownerReferences[*].name == "klevr-agent")]}{.metadata.name}{"\n"}{end}'| xargs kubectl delete -n ${KUBENAMESPACE} po
  #kubectl delete -n ${KUBENAMESPACE} po provbee
  $kubedel ${KUBENAMESPACE} daemonset/klevr-agent
  $kubedel ${KUBENAMESPACE} clusterrolebinding ${KUBESERVICEACCOUNT}-rbac
  $kubedel ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-secrets
  $kubedel ${KUBENAMESPACE} configmap ${KUBENAMESPACE}-agent-config
  $kubedel ${KUBENAMESPACE} role nexclipper-role
  $kubedel ${KUBENAMESPACE} rolebinding ${KUBENAMESPACE}-rb
  $kubedel ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-kubeconfig
  $kubedel ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-ssh-key
  $kubedel ${KUBENAMESPACE} sa ${KUBESERVICEACCOUNT}
  kubectl delete ns $NEXNS
  kubectl delete ns ${KUBENAMESPACE}
}


############ RUN CHK
if [[ $DEL =~ ^([yY][eE][sS]|[yY])$ ]]; then goodbye_provbee ; fi
