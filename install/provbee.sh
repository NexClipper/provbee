#!/bin/bash
UNAMECHK=`uname`
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
### console connection check
nexconsolechk(){
  urltest="curl -o /dev/null --silent --head --write-out '%{http_code}' ${K_MANAGER_URL}/swagger/doc.json"
  if $urltest &>/dev/null ; then
  	printf "%s\n" "NexClipper installer "
else
  	printf "%b%s\n" "\033[91m$K_MANAGER_URL\033[0m Not connection. check your network"
    if [[ $DELTEST == "" ]]; then exit 1; fi
  fi
}
nexconsolechk

## Provbee, Klevr-agent img ##
if [[ $TAGPROV == "" ]]; then TAGPROV="latest" ; fi
if [[ $TAGKLEVR == "" ]]; then TAGKLEVR="latest" ; fi

### System check
######################################################################################
if [[ $UNAMECHK == "Darwin" ]]; then
  if [[ $WORKDIR == "" ]]; then WORKDIR="$HOME/klevry"; fi
else
  if [[ $WORKDIR == "" ]]; then WORKDIR="$HOME/klevry"; fi
fi

if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
KUBECONFIG_FILE="$WORKDIR/kube-config-nexc"

#Host IP Check
if [[ $HOSTIP == "" ]]; then
	if [[ $UNAMECHK == "Darwin" ]]; then
		HOSTIP=$(ifconfig | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|head -n1)
	else
		HOSTIP=$(ip a | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|awk -F "/" '{print $1}'|head -n1)
	fi
fi
######################################################################################
##
info(){
  echo -en '\033[92m[INFO]  \033[0m' "$@"
}
warn()
{
  echo -e '\033[93m[WARN] \033[0m' "$@" >&2
}
fatal()
{
  echo -e '\033[91m[ERROR] \033[0m' "$@" >&2
  exit 1
}


############
# BAREMATAL
############
if [[ $K_PLATFORM == "baremetal" ]]; then
	info "baremetal install" echo
  info "curl zxz.kr/docker|bash ............ Docker install test" echo
fi
#########################################################################

############
# K3S INSTALL
############
k3s_checking(){
if [[ $UNAMECHK == "Linux" ]]; then
  k3s_rootchecking
  else
  echo ">> K3s Install - only Linux"
  echo ">> https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/#operating-systems"
fi  
}

k3s_rootchecking(){
  if [ $(id -u) -eq 0 ]; then 
    k3s_install 
  else
    fatal "Run as Root user"
    exit 1
  fi
}

k3s_install() {
#K3s Server Install
curl -sfL https://get.k3s.io | sh -
#curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.18.10+k3s2 sh -

## cluster-ip change
if [ -f /etc/systemd/system/k3s.service ]; then
	#sed -i 's/server \\/server --bind-address 0.0.0.0 \\/g' /etc/systemd/system/k3s.service
	sed -i 's/server \\/server --bind-address '$HOSTIP' \\/g' /etc/systemd/system/k3s.service
	systemctl daemon-reload
	systemctl restart k3s
fi
}
if [[ $K3S_SET =~ ^([yY][eE][sS]|[yY])$ ]]; then k3s_checking ; fi
#########################################################################

############
# KUBERNETES
############
if [[ $K_PLATFORM == "kubernetes" ]]; then
    if [ $(which kubectl|wc -l) -eq 0 ]; then fatal "Kubectl run failed!, Your command server check plz."; fi
    if [ $(kubectl version --short | grep Server | wc -l) -eq 0 ]; then warn "kubernetes cluster check plz."; cat ~/.kube/config; exit 1; fi 
############## kube-config file gen.
kubeconfig_gen() {

CLUSTERNAME=$(kubectl config get-contexts $(kubectl config current-context) | awk '{print $3}' | grep -v CLUSTER)
SVRCLUSTER=$(kubectl config view -o jsonpath='{.clusters[?(@.name == "'$CLUSTERNAME'")].cluster.server}')
USERTOKENNAME=$(kubectl get serviceaccount $KUBESERVICEACCOUNT --namespace $KUBENAMESPACE -o jsonpath='{.secrets[*].name}')
kubectl get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o jsonpath='{.data.ca\.crt}'|base64 -d > $WORKDIR/test.zzz
TOKEN=$(kubectl get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o jsonpath='{.data.token}'|base64 -d)

info
kubectl config set-cluster "${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --server="${SVRCLUSTER}" \
    --certificate-authority="$WORKDIR/test.zzz" \
    --embed-certs=true
rm -rf $WORKDIR/test.zzz

info
kubectl config set-credentials \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --token="${TOKEN}"

info
kubectl config set-context \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --cluster="${CLUSTERNAME}" \
    --user="${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --namespace="${KUBENAMESPACE}"
info
kubectl config use-context \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}"

#kube config file secert
info
kubectl -n $KUBENAMESPACE create secret generic $KUBESERVICEACCOUNT-kubeconfig --from-file=kubeconfig=$KUBECONFIG_FILE
}
####################################### SSH KEY Create
ssh_keycreate(){
  mkdir -p $WORKDIR/.ssh
  cat /dev/zero | ssh-keygen -t rsa -b 4096 -q -P "" -f $WORKDIR/.ssh/id_rsa > /dev/null
  cat $WORKDIR/.ssh/id_rsa.pub > $WORKDIR/.ssh/authorized_keys
  cat << EOF > $WORKDIR/.ssh/config
Host *
	StrictHostKeyChecking no
	UserKnownHostsFile /dev/null
  LogLevel ERROR
EOF
}
ssh_keycreate

#### K3s User permission Checking!
K3SPERM=$(kubectl cluster-info 2>&1 | grep -E "k3s.*permission"|wc -l)
if [ $K3SPERM -eq 0 ]; then
  if [[ $(kubectl get node -o jsonpath='{.items[*].metadata.managedFields[*].manager}') == "k3s" ]]; then
    if [ $(id -u) -ne 0 ]; then echo "run as root user";exit 1 ; fi
  fi
else    
  echo "run as root user"
fi

############################################### kubectl command RUN
info 
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${KUBENAMESPACE}
EOF

info 
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${KUBESERVICEACCOUNT}
  namespace: ${KUBENAMESPACE}
---
EOF


#info '### sample ssh secret'
info
kubectl -n $KUBENAMESPACE create secret generic $KUBESERVICEACCOUNT-ssh-key --from-file=pubkey=$WORKDIR/.ssh/id_rsa.pub --from-file=prikey=$WORKDIR/.ssh/id_rsa --from-file=conf=$WORKDIR/.ssh/config
#info '### Secret??? create'
info
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  namespace: ${KUBENAMESPACE}
  name: nex-secrets
  labels:
    app.kubernetes.io/name: nexclipper-kubernetes-agent
stringData:
  username: ${KUBESERVICEACCOUNT}
  nexclipper-api-token: ${K_API_KEY}
---
EOF
info
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ${KUBENAMESPACE}
  name: ${KUBENAMESPACE}-agent-config
  labels:
    app.kubernetes.io/name: nexclipper-kubernetes-agent
data:
  instance-name: "${K_ZONE_ID}"
---
EOF
info
# '### Provbee k8s authorization create'
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${KUBENAMESPACE}
  name: nexclipper-role
rules:
- apiGroups: [""]
  resources: ["pods"] # Object 지정
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] # Action 제어 
---
EOF
info
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${KUBESERVICEACCOUNT}-rbac
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: ${KUBESERVICEACCOUNT}
    namespace: ${KUBENAMESPACE}
---
EOF
info
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: ${KUBENAMESPACE}
  name: nexclipper-rb
subjects:
- kind: ServiceAccount
  name: ${KUBESERVICEACCOUNT}
  namespace: ${KUBENAMESPACE}
roleRef:
  kind: Role 
  name: nexclipper-role
  apiGroup: rbac.authorization.k8s.io
---
EOF

kubeconfig_gen
############# Provbee-Deployment & Service
info
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Service
metadata:
  name: provbee-service
  namespace: ${KUBENAMESPACE}
spec:
  selector:
    name: provbee
  clusterIP: None
  ports:
  - name: provbee # Actually, no port is needed.
    port: 22
    targetPort: 22
EOF
info
cat <<EOF | kubectl apply -f - 
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: ${KUBENAMESPACE}
  name: provbee
  labels:
    name: provbee
spec:
  selector:
    matchLabels:
      name: provbee
  template:
    metadata:
      labels:
        name: provbee
    spec:
      serviceAccountName: ${KUBESERVICEACCOUNT}
      containers:
      - name: provbee
        image: nexclipper/provbee:${TAGPROV}
        command: ['bash', '-c', '/entrypoint.sh']
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        volumeMounts:
        - name: ssh-auth
          mountPath: /data/.provbee/
        - name: kube-config
          mountPath: /root/.kube/
      volumes:
      - name: ssh-auth
        secret:
          secretName: ${KUBESERVICEACCOUNT}-ssh-key
    #      defaultMode: 0644
          items:
          - key: pubkey
            path: configmap_authkey
      - name: kube-config
        secret:
          secretName: ${KUBESERVICEACCOUNT}-kubeconfig
          defaultMode: 0644
          items:
          - key: kubeconfig
            path: config
---
EOF

#############ProvBee-Pod & Service
#info
#cat <<EOF | kubectl apply -f -
#apiVersion: v1
#kind: Service
#metadata:
#  name: provbee-service
#  namespace: ${KUBENAMESPACE}
#spec:
#  selector:
#    name: klevr
#  clusterIP: None
#  ports:
#  - name: provbee # Actually, no port is needed.
#    port: 22
#    targetPort: 22
#---
#EOF
#info
#cat <<EOF | kubectl apply -f -
#apiVersion: v1
#kind: Pod
#metadata:
#  namespace: ${KUBENAMESPACE}
#  name: provbee
#  labels:
#    name: klevr
#spec:
#  hostname: provbee
#  subdomain: provbee-service
#  serviceAccountName: ${KUBESERVICEACCOUNT}
#  containers:
#  - name: provbee
#    image: nexclipper/provbee:${TAGPROV}
#    command: ['bash', '-c', '/entrypoint.sh']
#    resources:
#      requests:
#        memory: "128Mi"
#        cpu: "250m"
#      limits:
#        memory: "256Mi"
#        cpu: "500m"    
#    volumeMounts:
#    - name: ssh-auth
#      mountPath: /data/.provbee/
#    - name: kube-config
#      mountPath: /root/.kube/
#  volumes:
#  - name: ssh-auth
#    secret:
#      secretName: ${KUBESERVICEACCOUNT}-ssh-key
##      defaultMode: 0644
#      items:
#      - key: pubkey
#        path: configmap_authkey
#  - name: kube-config
#    secret:
#      secretName: ${KUBESERVICEACCOUNT}-kubeconfig
#      defaultMode: 0644
#      items:
#      - key: kubeconfig
#        path: config
#---
#EOF

##########Klevr-agent
info
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: klevr-agent
  namespace: ${KUBENAMESPACE}
  labels:
    name: klevr
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: klevr-agent
  template:
    metadata:
      labels:
        app.kubernetes.io/name: klevr-agent
    spec:
      containers:
      - image: nexclipper/klevr-agent:${TAGKLEVR}
        name: klevr-agent
        env:
        - name: K_API_KEY
          value: "${K_API_KEY}"
        - name: K_PLATFORM
          value: "${K_PLATFORM}"
        - name: K_MANAGER_URL
          value: "${K_MANAGER_URL}"
        - name: K_ZONE_ID
          value: "${K_ZONE_ID}"
#        imagePullPolicy: Always
        ports:
        - containerPort: 18800
          name: klevr-agent
        volumeMounts:
        - name: ssh-auth
          mountPath: /root/.ssh/
      volumes:
      - name: ssh-auth
        secret:
          secretName: $KUBESERVICEACCOUNT-ssh-key
          defaultMode: 0600
          items:
          - key: prikey
            path: id_rsa
          - key: conf
            path: config
EOF
#FILE gen

fi

##########################################
#provbee run chk
namespacechk(){
echo ":+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:"
namespchk=$(kubectl get ns $KUBENAMESPACE 2>/dev/null |grep -v NAME| wc -l )
echo -n -e "## Namespace \"$KUBENAMESPACE\" check\t" "\033[91mwait...🍯 \033[0m"
sleep 3
while [ $namespchk != "1" ]
do
        nszzz=$((nszzz+1))
        echo -n -e "\r## Namespace \"$KUBENAMESPACE\" check\t" "\033[91m $(seq -f "%02g" $nszzz|tail -n1)/99 wait...\033[0m"
        namespchk=$(kubectl get ns $KUBENAMESPACE 2>/dev/null |grep -v NAME| wc -l)
        sleep 3
        if [ $nszzz == "99" ]; then echo "failed. restart plz."; exit 1; fi
done
echo -e "\r## Namespace \"$KUBENAMESPACE\" check\t" "\033[92m OK.            \033[0m"
provbeeok
}

provbeeok(){
echo -n -e "## NexClipper system check\t" "\033[91mwait...🍯 \033[0m"
sleep 5
provinstchk=$(kubectl get pods -n $KUBENAMESPACE 2>/dev/null |grep -v NAME| grep -v Running | wc -l)
while [ $provinstchk != "0" ];
do
        przzz=$((przzz+1))
        beechk=$(kubectl get pods -n $KUBENAMESPACE 2>/dev/null |grep -v NAME| grep provbee | grep unning | wc -l)
        agentchk=$(kubectl get pods -n $KUBENAMESPACE 2>/dev/null |grep -v NAME| grep klevr-agent | grep unning | wc -l)
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
######################################################################END LINE

#DELETE TEST
delete_test(){
  #kubectl exec -it -n ${KUBENAMESPACE} provbee -- kubectl delete -f /data/klevry/kube-prometheus/
  #kubectl exec -it -n ${KUBENAMESPACE} provbee -- kubectl delete -f /data/klevry/kube-prometheus/setup
  #helm uninstall nex-pro  $(kubectl config current-context)
  kubectl exec -it -n ${KUBENAMESPACE} provbee -- helm uninstall nex-pro
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
  rm $KUBECONFIG_FILE >/dev/null 2>&1

}
if [[ $DELTEST =~ ^([yY][eE][sS]|[yY])$ ]]; then delete_test ; fi
