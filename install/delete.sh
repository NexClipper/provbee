#!/bin/bash
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
###

#GoodBye!!
goodbye_provbee(){
  kubectl exec -it -n ${KUBENAMESPACE} deployment/provbee -- busybee tobs uninstall nexclipper
  kubectl delete -n ${KUBENAMESPACE} svc provbee-service
  kubectl get po -n ${KUBENAMESPACE} -o jsonpath='{range $.items[?(@.metadata.ownerReferences[*].name == "klevr-agent")]}{.metadata.name}{"\n"}{end}'| xargs kubectl delete -n ${KUBENAMESPACE} po
  kubectl delete -n ${KUBENAMESPACE} po provbee
  kubectl delete -n ${KUBENAMESPACE} clusterrolebinding ${KUBESERVICEACCOUNT}-rbac
  kubectl delete -n ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-secrets
  kubectl delete -n ${KUBENAMESPACE} configmap ${KUBENAMESPACE}-agent-config
  kubectl delete -n ${KUBENAMESPACE} role nexclipper-role
  kubectl delete -n ${KUBENAMESPACE} rolebinding ${KUBENAMESPACE}-rb
  kubectl delete -n ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-kubeconfig
  kubectl delete -n ${KUBENAMESPACE} secret ${KUBESERVICEACCOUNT}-ssh-key
  kubectl delete -n ${KUBENAMESPACE} sa ${KUBESERVICEACCOUNT}
  kubectl delete -n ${KUBENAMESPACE} ns ${KUBENAMESPACE}
}


############ RUN CHK
if [[ $DEL =~ ^([yY][eE][sS]|[yY])$ ]]; then goodbye_provbee ; fi
