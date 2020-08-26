#!/bin/bash
WORKDIR="/data/klevry"
if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
#for i in "$@"
#do
#case $i in
#        --platform=*)
#        PLATFORM="${i#*=}"
#        shift
#        ;;
#        --instance-name=*)
#        INSTANCENAME="${i#*=}"
#        shift
#        ;;
#        --api-token=*)
#        APITOKEN="${i#*=}"
#        shift
#        ;;
#        --user-name=*)
#        USERNAME="${i#*=}"
#        shift
#        ;;
#esac
#done

#echo "PLATFORM          = ${PLATFORM}"
#echo "INSTANCENAME      = ${INSTANCENAME}"
#echo "APITOKEN          = ${APITOKEN}"
#echo "USERNAME          = ${USERNAME}"
######################################################################################
KUBENAMESPACE="nexclipper"
KUBESERVICEACCOUNT="nexc"
#Host IP Check
if [[ $HOSTIP == "" ]]; then
	HOSTIP=$(ip a | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|awk -F "/" '{print $1}'|head -n1)
fi
######################################################################################

############
# BAREMATAL
############
if [[ $K_PLATFORM == "baremetal" ]]; then
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
#if [[ $APITOKEN == "" ]];then APITOKEN=$(cat /var/lib/rancher/k3s/server/node-token); fi
}
if [[ $K3S_SET =~ ^([yY][eE][sS]|[yY])$ ]]; then k3s_install ; fi
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
    if [ $(which kubectl|wc -l) -eq 0 ]; then echo "Kubectl run failed!, Your command server check plz."; exit 1; fi
    if [ $(kubectl version --short | grep Server | wc -l) -eq 0 ]; then echo "kubernetes cluster check plz."; exit 1; fi 
############## kube-config file gen.
kubeconfig_gen() {
KUBECONFIG_FILE="$WORKDIR/kube-config"
SVRCLUSTER=$(kubectl config view -o yaml|awk '/server/{print $2}')
CLUSTERNAME=$(kubectl config get-contexts $(kubectl config current-context) | awk '{print $3}' | grep -v CLUSTER)
USERTOKENNAME=$(kubectl get serviceaccount $KUBESERVICEACCOUNT --namespace $KUBENAMESPACE -o yaml|awk '/- name/{print $3}')
kubectl get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o yaml|awk '/^(  ca.crt)/{print $2}'|base64 -d > $WORKDIR/test.zzz
TOKEN=$(kubectl get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o yaml|awk '/^(  token)/{print $2}'|base64 -d)

kubectl config set-cluster "${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --server="${SVRCLUSTER}" \
    --certificate-authority="$WORKDIR/test.zzz" \
    --embed-certs=true
rm -rf $WORKDIR/test.zzz

kubectl config set-credentials \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --token="${TOKEN}"

kubectl config set-context \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}" \
    --cluster="${CLUSTERNAME}" \
    --user="${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --namespace="${KUBENAMESPACE}"

kubectl config use-context \
    "${KUBESERVICEACCOUNT}-${KUBENAMESPACE}-${CLUSTERNAME}" \
    --kubeconfig="${KUBECONFIG_FILE}"
}

############################################### kubectl command RUN
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${KUBENAMESPACE}
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${KUBESERVICEACCOUNT}
  namespace: ${KUBENAMESPACE}
---
EOF
#sample ssh secret
kubectl -n $KUBENAMESPACE create secret generic $KUBESERVICEACCOUNT-ssh-key --from-file=pubkey=$WORKDIR/.ssh/id_rsa.pub --from-file=prikey=$WORKDIR/.ssh/id_rsa --from-file=conf=$WORKDIR/.ssh/config zxz=0

echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
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
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ${KUBENAMESPACE}
  name: ${KUBENAMESPACE}-agent-config
  labels:
    app.kubernetes.io/name: nexclipper-kubernetes-agent
data:
  instance-name: ${K_ZONE_ID}
---
EOF
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
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
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
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
echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
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

echo ">>>>> kube yaml test - $zxz"; zxz=$((zxz+1))
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
#    - name: terraformstpath
#      mountPath: /data/terraform_state
#    - name: zzz
#      mountPath: /data/klevry
#    - name: ssh
#      mountPath: /root/.ssh/
    - name: ssh-auth
      mountPath: /root/.ssh/
  volumes:
#  - name: terraformstpath
#    hostPath:
#      path: /tmp/
#      type: Directory
#  - name: zzz
#    hostPath:
#      path: /data/klevry
#      type: Directory
#  - name: ssh
#    hostPath:
#      path: /root/.ssh/
#      type: Directory
  - name: ssh-auth
    secret:
      secretName: $KUBESERVICEACCOUNT-ssh-key
      defaultMode: 0644
      items:
      - key: pubkey
        path: authorized_keys
---
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
#      hostname: agent
#      subdomain: provbee-service
      containers:
      - image: klevry/klevr-agent:latest
        name: agent
        env:
        - name: K_API_KEY
          value: ${K_API_KEY}
        - name: K_PLATFORM
          value: ${K_PLATFORM}
        - name: K_MANAGER_URL
          value: ${K_MANAGER_URL}
        - name: K_ZONE_ID
          value: ${K_ZONE_ID}
        ports:
        - containerPort: 18800
          name: klevr-agent
        volumeMounts:
#        - name: ssh
#          mountPath: /root/.ssh/
        - name: ssh-auth
          mountPath: /root/.ssh/
        - name: ssh-conf
          mountPath: /root/.ssh/
      volumes:
#      - name: ssh
#        hostPath:
#          path: /root/.ssh/
#          type: Directory
      - name: ssh-auth
        secret:
          secretName: $KUBESERVICEACCOUNT-ssh-key
          defaultMode: 0600
          items:
          - key: prikey
            path: id_rsa
      - name: ssh-conf
        secret:
          secretName: $KUBESERVICEACCOUNT-ssh-key
          defaultMode: 0644
          items:
          - key: conf
            path: config
EOF

#FILE gen


temp_ssh(){
  mkdir -p $WORKDIR/.ssh
  cat /dev/zero | ssh-keygen -t rsa -b 4096 -q -P "" -f $WORKDIR/.ssh/id_rsa
  cat $WORKDIR/.ssh/id_rsa.pub >> $WORKDIR/.ssh/authorized_keys
  cat << EOF > ${WORKDIR}/.ssh/config
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

######################################################################END LINE
#END TSET
endtest(){
  rm ./zzz.tmp 
  echo $K_API_KEY >> ./zzz.tmp
  echo $K_PLATFORM >> ./zzz.tmp
  echo $K_MANAGER_URL >> ./zzz.tmp
  echo $K_ZONE_ID >> ./zzz.tmp
  echo $K3S_SET >> ./zzz.tmp
}
endtest


#DELETE TEST
delete_test(){
  kubectl delete -n nexclipper svc provbee-service
  kubectl delete -n nexclipper provbee
  kubectl delete -n nexclipper clusterrolebinding ${KUBESERVICEACCOUNT}-rbac
  kubectl delete -n nexclipper sa ${KUBESERVICEACCOUNT}
  kubectl delete -n nexclipper secret ${KUBESERVICEACCOUNT}-secrets
  kubectl delete -n nexclipper configmap ${KUBENAMESPACE}-agent-config
  kubectl delete -n nexclipper role nexclipper-role
  kubectl delete -n nexclipper rolebinding ${KUBENAMESPACE}-rb
  kubectl delete -n nexclipper ns ${KUBENAMESPACE}
# agent???
}
if [[ $DELTEST =~ ^([yY][eE][sS]|[yY])$ ]]; then delete_test ; fi
