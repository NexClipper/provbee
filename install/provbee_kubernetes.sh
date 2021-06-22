#!/bin/bash
### sed
SED_NS="s/\${KUBENAMESPACE}/$KUBENAMESPACE/g"
SED_SVCAC="s/\${KUBESERVICEACCOUNT}/$KUBESERVICEACCOUNT/g"
SED_K_API="s/\${K_API_KEY}/$K_API_KEY/g"
SED_K_PLT="s/\${K_PLATFORM}/$K_PLATFORM/g"
SED_K_MURL="s#\${K_MANAGER_URL}#$K_MANAGER_URL#g"
SED_K_ZID="s/\${K_ZONE_ID}/$K_ZONE_ID/g"
SED_TAG_K="s/\${TAGKLEVR}/$TAGKLEVR/g"
SED_TAG_P="s/\${TAGPROV}/$TAGPROV/g"

############## kube-config file gen.
kubeconfig_gen() {
CLUSTERNAME=$($KU_CMD config get-contexts $($KU_CMD config current-context) | awk '{print $3}' | grep -v CLUSTER)
SVRCLUSTER=$($KU_CMD config view -o jsonpath='{.clusters[?(@.name == "'$CLUSTERNAME'")].cluster.server}')
USERTOKENNAME=$($KU_CMD get serviceaccount $KUBESERVICEACCOUNT --namespace $KUBENAMESPACE -o jsonpath='{.secrets[*].name}')
$KU_CMD get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o jsonpath='{.data.ca\.crt}'|base64 -d > $WORKDIR/test.zzz
TOKEN=$($KU_CMD get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o jsonpath='{.data.token}'|base64 -d)

$KU_CMD config set-cluster "${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --server="${SVRCLUSTER}" \
    --certificate-authority="$WORKDIR/test.zzz" \
    --embed-certs=true
rm -rf $WORKDIR/test.zzz

$KU_CMD config set-credentials \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --token="${TOKEN}"

$KU_CMD config set-context \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --cluster="${CLUSTERNAME}" \
    --user="${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --namespace="${KUBENAMESPACE}"
$KU_CMD config use-context \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}"

#kube config file secert
$KU_CMD -n $KUBENAMESPACE create secret generic $KUBESERVICEACCOUNT-kubeconfig --from-file=kubeconfig=$KUBECONFIG_FILE
}


##################### First Banner
info "Welcome to NexClipper!"
############################################### kubectl command RUN
#info #namespace, serviceaccount create
curl -sL ${INST_SRC}/install/yaml/provbee-00.yaml \
|sed -e $SED_NS -e $SED_SVCAC \
|$KU_CMD apply -f -

#info '### sample ssh secret'
$KU_CMD -n $KUBENAMESPACE create secret generic $KUBESERVICEACCOUNT-ssh-key --from-file=pubkey=$WORKDIR/.ssh/id_rsa.pub --from-file=prikey=$WORKDIR/.ssh/id_rsa --from-file=conf=$WORKDIR/.ssh/config

#info '### Secret??? create'
curl -sL ${INST_SRC}/install/yaml/provbee-01.yaml \
|sed -e $SED_NS -e $SED_SVCAC -e $SED_K_API -e $SED_K_ZID \
|$KU_CMD apply -f - 

#info kubeconfig gen
kubeconfig_gen

############# Provbee-Deployment & Service
curl -sL ${INST_SRC}/install/yaml/provbee-90.yaml \
|sed -e $SED_NS -e $SED_SVCAC -e $SED_TAG_P \
|$KU_CMD apply -f - 

########## Klevr-agent Deamonset
curl -sL ${INST_SRC}/install/yaml/provbee-91.yaml \
|sed -e $SED_NS -e $SED_SVCAC -e $SED_TAG_K -e $SED_K_API -e $SED_K_PLT -e $SED_K_MURL -e $SED_K_ZID \
|$KU_CMD apply -f - 

########## Webstork
#curl -sL ${INST_SRC}/install/yaml/webstork.yaml \
#|sed -e $SED_NS -e $SED_SVCAC \
#|$KU_CMD apply -f - 

#######################################