#!/bin/bash
UNAMECHK=`uname`
KUBENAMESPACE="nexclipper"
KUBESERVICEACCOUNT="nexc"
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
  k3s_install
  else
  echo ">> K3s Install - only Linux"
  echo ">> https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/#operating-systems"
fi  
}

k3s_install() {
#K3s Server Install
curl -sfL https://get.k3s.io | sh -

## cluster-ip change
if [ -f /etc/systemd/system/k3s.service ]; then
	#sed -i 's/server \\/server --bind-address 0.0.0.0 \\/g' /etc/systemd/system/k3s.service
	sed -i 's/server \\/server --bind-address '$HOSTIP' \\/g' /etc/systemd/system/k3s.service
	systemctl daemon-reload
	systemctl restart k3s
fi

##K3s agent Install
#curl -sfL https://get.k3s.io | K3S_URL=https://$MASTERIP:6443 K3S_TOKEN=///SERVER$(cat /var/lib/rancher/k3s/server/node-token) sh -
############ TOKEN
#if [[ $APITOKEN == "" ]];then APITOKEN=$(cat /var/lib/rancher/k3s/server/node-token); fi
}
if [[ $K3S_SET =~ ^([yY][eE][sS]|[yY])$ ]]; then k3s_checking ; fi
#########################################################################
########## TEST MODE 
# GET Kube config Setting ##
# nexcloud internal k8s cluster test 
devtest(){
  mkdir -p ~/.kube 
  curl pubkey.nexclipper.io:9876/kube-config -o ~/.kube/config
  if [ $(which kubectl|wc -l) -eq 0 ]; then curl -sL zxz.kr/kubectl|bash; fi
  exit 1
}
## TEST LINE
if [[ $DEVTEST =~ ^([yY][eE][sS]|[yY])$ ]]; then devtest ; fi
############################################## TEST MODE END LINE

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
EOF
}
ssh_keycreate

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
apiVersion: rbac.authorization.k8s.io/v1beta1
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

############ProvBee-Service
info
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: provbee-service
  namespace: ${KUBENAMESPACE}
spec:
  selector:
    name: klevr
  clusterIP: None
  ports:
  - name: provbee # Actually, no port is needed.
    port: 22
    targetPort: 22
---
EOF
############ProvBee Pod
info
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  namespace: ${KUBENAMESPACE}
  name: provbee
  labels:
    name: klevr
spec:
  hostname: provbee
  subdomain: provbee-service
  serviceAccountName: ${KUBESERVICEACCOUNT}
  containers:
  - name: provbee
    image: nexclipper/provbee:latest
    command: ['bash', '-c', '/entrypoint.sh']
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
##########Klevr-agent
info
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: agent
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
      - image: klevry/klevr-agent:latest
        name: agent
        env:
        - name: K_API_KEY
          value: "${K_API_KEY}"
        - name: K_PLATFORM
          value: "${K_PLATFORM}"
        - name: K_MANAGER_URL
          value: "${K_MANAGER_URL}"
        - name: K_ZONE_ID
          value: "${K_ZONE_ID}"
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

info echo ":+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:+:"
kubectl get po,svc -n $KUBENAMESPACE

fi

######################################################################END LINE
#END TSET
endtest(){
  rm ./zzz.tmp >/dev/null 2>&1 
  echo $K_API_KEY >> ./zzz.tmp
  echo $K_PLATFORM >> ./zzz.tmp
  echo $K_MANAGER_URL >> ./zzz.tmp
  echo $K_ZONE_ID >> ./zzz.tmp
  echo $K3S_SET >> ./zzz.tmp
}
#endtest


#DELETE TEST
delete_test(){
  kubectl delete -f /data
  kubectl delete -n nexclipper svc provbee-service
  kubectl get po -n nexclipper -o jsonpath='{range $.items[?(@.metadata.ownerReferences[*].name == "agent")]}{.metadata.name}{"\n"}{end}'| xargs kubectl delete -n nexclipper po
  kubectl delete -n nexclipper clusterrolebinding ${KUBESERVICEACCOUNT}-rbac
  kubectl delete -n nexclipper secret ${KUBESERVICEACCOUNT}-secrets
  kubectl delete -n nexclipper configmap ${KUBENAMESPACE}-agent-config
  kubectl delete -n nexclipper role nexclipper-role
  kubectl delete -n nexclipper rolebinding ${KUBENAMESPACE}-rb
  kubectl delete -n nexclipper secret ${KUBESERVICEACCOUNT}-kubeconfig
  kubectl delete -n nexclipper secret ${KUBESERVICEACCOUNT}-ssh-key
  kubectl delete -n nexclipper provbee
  kubectl delete -n nexclipper sa ${KUBESERVICEACCOUNT}
  kubectl delete -n nexclipper ns ${KUBENAMESPACE}
  rm $KUBECONFIG_FILE >/dev/null 2>&1
#/usr/local/bin/k3s-killall.sh
#/usr/local/bin/k3s-uninstall.sh
}
if [[ $DELTEST =~ ^([yY][eE][sS]|[yY])$ ]]; then delete_test ; fi
