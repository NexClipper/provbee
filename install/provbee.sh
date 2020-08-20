#!/bin/bash
WORKDIR="/data/klevry"
if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
for i in "$@"
do
case $i in
        --platform=*)
        PLATFORM="${i#*=}"
        shift
        ;;
        --instance-name=*)
        INSTANCENAME="${i#*=}"
        shift
        ;;
        --api-token=*)
        APITOKEN="${i#*=}"
        shift
        ;;
        --user-name=*)
        USERNAME="${i#*=}"
        shift
        ;;
esac
done

#echo "PLATFORM          = ${PLATFORM}"
#echo "INSTANCENAME      = ${INSTANCENAME}"
#echo "APITOKEN          = ${APITOKEN}"
#echo "USERNAME          = ${USERNAME}"
######################################################################################
NAMESPACE="nexclipper"
INSTANCENAME="zzzzzz"
#Host IP Check
if [[ $HOSTIP == "" ]]; then
	HOSTIP=$(ip a | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|awk -F "/" '{print $1}'|head -n1)
fi
######################################################################################

############
# BAREMATAL
############
if [[ $PLATFORM == "baremetal" ]]; then
	echo "baremetal install"
    echo "curl zxz.kr/docker|bash ............ Docker install test"
fi
#########################################################################

############
# K3S INSTALL
############

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
if [[ $APITOKEN == "" ]];then APITOKEN=$(cat /var/lib/rancher/k3s/server/node-token); fi
}
if [[ $K3S_SET =~ ^([yY][eE][sS]|[yY])$ ]]; then k3s_install ; fi
#########################################################################



############
# KUBERNETES
############
if [[ $PLATFORM == "kubernetes" ]]; then
    if [ $(which kubectl|wc -l) -eq 0 ]; then echo "Kubectl run failed!, Your command server check plz."; exit 1; fi
    if [ $(kubectl version --short | grep Server | wc -l) -eq 0 ]; then echo "kubernetes cluster check plz."; exit 1; fi 

############## kube-config file gen.
kubeconfig_gen() {
KUBECONFIG_FILE="$WORKDIR/kube-config"
SVRCLUSTER=$(kubectl config view -o yaml|awk '/server/{print $2}')
CLUSTERNAME=$(kubectl config get-contexts $(kubectl config current-context) | awk '{print $3}' | grep -v CLUSTER)
USERTOKENNAME=$(kubectl get serviceaccount $USERNAME --namespace $NAMESPACE -o yaml|awk '/- name/{print $3}')
kubectl get secret $USERTOKENNAME --namespace $NAMESPACE -o yaml|awk '/^(  ca.crt)/{print $2}'|base64 -d > $WORKDIR/test.zzz
TOKEN=$(kubectl get secret $USERTOKENNAME --namespace $NAMESPACE -o yaml|awk '/^(  token)/{print $2}'|base64 -d)

kubectl config set-cluster "${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --server="${SVRCLUSTER}" \
    --certificate-authority="$WORKDIR/test.zzz" \
    --embed-certs=true
rm -rf $WORKDIR/test.zzz

kubectl config set-credentials \
    "${USERNAME}-${NAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --token="${TOKEN}"

kubectl config set-context \
    "${USERNAME}-${NAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --cluster="${CLUSTERNAME}" \
    --user="${USERNAME}-${NAMESPACE}-${CLUSTERNAME}" \
    --namespace="${NAMESPACE}"

kubectl config use-context \
    "${USERNAME}-${NAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}"
}

############################################### kubectl command RUN
zxz=0
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${USERNAME}
  namespace: ${NAMESPACE}
---
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  namespace: ${NAMESPACE}
  name: nex-secrets
  labels:
    app.kubernetes.io/name: nexclipper-kubernetes-agent
stringData:
  username: ${USERNAME}
  nexclipper-api-token: ${APITOKEN}
---
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ${NAMESPACE}
  name: nexclipper-agent-config
  labels:
    app.kubernetes.io/name: nexclipper-kubernetes-agent
data:
  instance-name: ${INSTANCENAME}
---
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${NAMESPACE}
  name: nexclipper-role
rules:
- apiGroups: [""]
  resources: ["pods"] # Object 지정
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] # Action 제어 
---
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: ${USERNAME}-rbac
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: ${USERNAME}
    namespace: ${NAMESPACE}
---
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: ${NAMESPACE}
  name: nexclipper-rb
subjects:
- kind: ServiceAccount
  name: ${USERNAME}
  namespace: ${NAMESPACE}
roleRef:
  kind: Role 
  name: nexclipper-role
  apiGroup: rbac.authorization.k8s.io
---
EOF

echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: provbee-service
  namespace: ${NAMESPACE}
spec:
  selector:
    name: klevr
  clusterIP: None
  ports:
  - name: provbee # Actually, no port is needed.
    port: 22
    targetPort: 22
---
apiVersion: v1
kind: Pod
metadata:
  namespace: ${NAMESPACE}
  name: provbee
  labels:
    name: klevr
spec:
  hostname: provbee
  subdomain: provbee-service
  serviceAccountName: ${USERNAME}
  containers:
  - name: provbee
    image: nexclipper/provbee:latest
    command: ['bash', '-c', '/entrypoint.sh']
    volumeMounts:
    - name: terraformstpath
      mountPath: /data/terraform_state
    - name: zzz
      mountPath: /data/klevry
    - name: ssh
      mountPath: /root/.ssh/
  volumes:
  - name: terraformstpath
    hostPath:
      path: /tmp/
      type: Directory
  - name: zzz
    hostPath:
      path: /data/klevry
      type: Directory
  - name: ssh
    hostPath:
      path: /root/.ssh/
      type: Directory
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: agent
  namespace: ${NAMESPACE}
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
#      hostname: agent
#      subdomain: provbee-service
      containers:
      - image: klevry/klevr-agent:latest
        name: agent
        env:
        - name: K_API_KEY
          value: "wnskslxptmxmrPwjd123"
        - name: K_PLATFORM
          value: "linux_laptop"
        - name: K_MANAGER_URL
          value: "192.168.15.163:8090"
        - name: K_ZONE_ID
          value: "8282"
        ports:
        - containerPort: 18800
          name: klevr-agent
        volumeMounts:
        - name: ssh
          mountPath: /root/.ssh/
      volumes:
      - name: ssh
        hostPath:
          path: /root/.ssh/
          type: Directory

EOF

#FILE gen


temp_ssh(){
cat /dev/zero | ssh-keygen -t rsa -b 4096 -q -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
cat << EOF >> ~/.ssh/config
Host *
	StrictHostKeyChecking no
	UserKnownHostsFile /dev/null
EOF
#cp -Rfvp ~/.ssh /data/
#touch /data/.ssh/lastupdate-$(date +%Y%m%d%H%M%S)
}
temp_ssh

kubeconfig_gen
fi
