#!/bin/bash
KUBECONFIG_FILE="$WORKDIR/kube-config-nexc"


### sed
SED_NS="s/\${KUBENAMESPACE}/$KUBENAMESPACE/g"
SED_SVCAC="s/\${KUBESERVICEACCOUNT}/$KUBESERVICEACCOUNT/g"
SED_K_API="s/\${K_API_KEY}/$K_API_KEY/g"
SED_K_PLT="s/\${K_PLATFORM}/$K_PLATFORM/g"
SED_K_MURL="s#\${K_MANAGER_URL}#$K_MANAGER_URL#g"
SED_K_ZID="s/\${K_ZONE_ID}/$K_ZONE_ID/g"
SED_TAG_K="s/\${TAGKLEVR}/$TAGKLEVR/g"
SED_TAG_P="s/\${TAGPROV}/$TAGPROV/g"


### kubectl command RUN
# info namespace create
$KU_CMD create namespace $KUBENAMESPACE
# info serviceaccount create
$KU_CMD -n $KUBENAMESPACE create serviceaccount $KUBESERVICEACCOUNT 

#info '### sample ssh secret'
$KU_CMD -n $KUBENAMESPACE create secret generic $KUBESERVICEACCOUNT-ssh-key --from-file=pubkey=$WORKDIR/.ssh/id_rsa.pub --from-file=prikey=$WORKDIR/.ssh/id_rsa --from-file=conf=$WORKDIR/.ssh/config

#info '### Secret??? create'
curl -sL ${INST_SRC}/install/yaml/provbee-01.yaml \
|sed -e $SED_NS -e $SED_SVCAC -e $SED_K_API -e $SED_K_ZID \
|$KU_CMD apply -f - 

#info kubeconfig gen
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


### provbee run chk
namespacechk(){
  echo ":+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:"
  namespchk=$($KU_CMD get ns $KUBENAMESPACE 2>/dev/null |grep -v NAME| wc -l )
  echo -n -e "## Namespace \"$KUBENAMESPACE\" check\t" "\033[91mwait...🍯 \033[0m"
  sleep 3
  while [ $namespchk != "1" ]
  do
          nszzz=$((nszzz+1))
          echo -n -e "\r## Namespace \"$KUBENAMESPACE\" check\t" "\033[91m $(seq -f "%02g" $nszzz|tail -n1)/99 wait...\033[0m"
          namespchk=$($KU_CMD get ns $KUBENAMESPACE 2>/dev/null |grep -v NAME| wc -l)
          sleep 3
          if [ $nszzz == "99" ]; then echo "failed. restart plz."; exit 1; fi
  done
  echo -e "\r## Namespace \"$KUBENAMESPACE\" check\t" "\033[92m OK.            \033[0m"
  provbeeok
}

provbeeok(){
  echo -n -e "## NexClipper system check\t" "\033[91mwait...🍯 \033[0m"
  sleep 5
  provinstchk=$($KU_CMD get pods -n $KUBENAMESPACE 2>/dev/null |grep -v NAME| grep -v Running | wc -l)
  while [ $provinstchk != "0" ];
  do
    przzz=$((przzz+1))
    beechk=$($KU_CMD get pods -n $KUBENAMESPACE 2>/dev/null |grep -v NAME| grep provbee | grep unning | wc -l)
    agentchk=$($KU_CMD get pods -n $KUBENAMESPACE 2>/dev/null |grep -v NAME| grep klevr-agent | grep unning | wc -l)
    if [ $beechk -eq 1 ]; then provb="\033[92mProvBee\033[0m";else provb="\033[91mProvBee\033[0m" ;fi
    if [ $agentchk -ge 1 ]; then klevra="\033[92mKlevr\033[0m";else klevra="\033[91mKlevr\033[0m" ;fi
    if [ $beechk -eq 1 ] && [ $agentchk -ge 1 ]; then
      provinstchk=0
    else
      provinstchk=1
    fi
    echo -n -e "\r## $provb / $klevra check  \t" "\033[91m $(seq -f "%02g" $przzz|tail -n1)/99 wait...🐝\033[0m"
    sleep 3
    if [ $przzz == "99" ]; then echo "Status check failed. restart plz."; exit 1; fi
  done
  echo -e "\r## NexClipper system check\t" "\033[92m OK. 🍯❤️🐝                \033[0m"
  echo -e "\a\033[92m ⛵ Enjoy NexClipper! :) \033[0m"
  echo ":+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:"
}
namespacechk

