#!/bin/bash
UNAMECHK=`uname`
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
<<<<<<< HEAD:install/provbee_old.sh
## Provbee, Klevr-agent img ##
if [[ $TAGPROV == "" ]]; then TAGPROV="latest" ; fi
if [[ $TAGKLEVR == "" ]]; then TAGKLEVR="latest" ; fi
if [[ $K_API_KEY == "" ]] || [[ $K_PLATFORM == "" ]] || [[ $K_MANAGER_URL == "" ]] || [[ $K_ZONE_ID == "" ]]; then
    echo "NexClipper Console Page's install script check"
    echo "bye~~"
    exit 1
fi
=======
#INST_SRC="https://raw.githubusercontent.com/NexClipper/provbee/master"
INST_SRC="https://raw.githubusercontent.com/NexClipper/provbee/installer"
TMP_DIR=$(mktemp -d -t provbee-inst.XXXXXXXXXX)

## information
info(){ echo -e '\033[92m[INFO]  \033[0m' "$@";}
warn(){ echo -e '\033[93m[WARN] \033[0m' "$@" >&2;}
fatal(){ echo -e '\033[91m[ERROR] \033[0m' "$@" >&2;exit 1;}
######################################################################################

### default check
default_chk(){
# Provbee, Klevr-agent tag check
  if [[ $TAGPROV == "" ]]; then TAGPROV="latest" ; fi
  if [[ $TAGKLEVR == "" ]]; then TAGKLEVR="latest" ; fi
>>>>>>> installer:install/provbee_new.sh

# Klevr Value check
  if [[ $K_API_KEY == "" ]] || [[ $K_PLATFORM == "" ]] || [[ $K_MANAGER_URL == "" ]] || [[ $K_ZONE_ID == "" ]]; then
    fatal "NexClipper Console Page's install script check"
  fi

# console connection check
  urltest="curl -o /dev/null --silent --head --write-out '%{http_code}' ${K_MANAGER_URL}/swagger/doc.json --connect-timeout 3"
  if $urltest &>/dev/null ; then
  	info "NexClipper serivce connection checking"
  else
  	fatal "\033[91m$K_MANAGER_URL\033[0m Not connection. check your network"
  fi
}
default_chk


### System check
<<<<<<< HEAD:install/provbee_old.sh
######################################################################################
if [[ $WORKDIR == "" ]]; then
    WORKDIR="$HOME/klevry"
else
    if [[ $UNAMECHK == "Darwin" ]]; then 
        WORKDIR="$HOME/$WORKDIR"
    else
        WORKDIR="$WORKDIR"
    fi
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
## information
info(){ echo -e '\033[92m[INFO]  \033[0m' "$@";}
warn(){ echo -e '\033[93m[WARN] \033[0m' "$@" >&2;}
fatal(){ echo -e '\033[91m[ERROR] \033[0m' "$@" >&2;exit 1;}
######################################################################################

#########################################################################
##Linux sudo auth check
sudopermission(){
if SUDOCHK=$(sudo -n -v 2>&1);test -z "$SUDOCHK"; then
    SUDO=sudo
    if [ $(id -u) -eq 0 ]; then SUDO= ;fi
else
	echo "root permission required"
	exit 1
fi
##OS install package mgmt check
pkgchk
}
##OSX timeout command : brew install coreutils
## package cmd Check
pkgchk(){
	LANG=en_US.UTF-8
	yum > /tmp/check_pkgmgmt 2>&1
	if [[ `(grep 'yum.*not\|not.*yum' /tmp/check_pkgmgmt)` == "" ]];then
		centosnap
	#else
		#Pkg_mgmt="apt-get"
		#apt update
	fi
}
#

############
# BAREMATAL
############
if [[ $K_PLATFORM == "baremetal" ]]; then
	info "baremetal install"
  info "curl zxz.kr/docker|bash ............ Docker install test" 
  ##temp
  K_PLATFORM="kubernetes"
fi
#########################################################################

############
# K3S INSTALL
############
k3s_checking(){
if [[ $UNAMECHK == "Linux" ]]; then
  k3s_rootchecking
  else
  warn ">> K3s Install - only Linux"
  fatal ">> https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/#operating-systems"
fi  
}

k3s_rootchecking(){
  if [ $(id -u) -eq 0 ]; then 
    k3s_install 
  else
    fatal "Run as Root user"
  fi
}

k3s_install() {
#K3s Server Install
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -

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
  PATH=/usr/local/bin:$PATH
  if [ $(which kubectl|wc -l) -eq 0 ]; then fatal "Kubectl run failed!, Your command server check plz."; fi
  if [ $(kubectl version --short | grep Server | wc -l) -eq 0 ]; then warn "kubernetes cluster check plz."; fatal "chkeck : \$cat ~/.kube/config"; fi 
################################
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
CLUSTERNAME=$(kubectl config get-contexts $(kubectl config current-context) | awk '{print $3}' | grep -v CLUSTER)
SVRCLUSTER=$(kubectl config view -o jsonpath='{.clusters[?(@.name == "'$CLUSTERNAME'")].cluster.server}')
USERTOKENNAME=$(kubectl get serviceaccount $KUBESERVICEACCOUNT --namespace $KUBENAMESPACE -o jsonpath='{.secrets[*].name}')
kubectl get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o jsonpath='{.data.ca\.crt}'|base64 -d > $WORKDIR/test.zzz
TOKEN=$(kubectl get secret $USERTOKENNAME --namespace $KUBENAMESPACE -o jsonpath='{.data.token}'|base64 -d)

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
=======
systemchk(){
# WorkDIR check or create
  if [ -z $WORKDIR ]; then WORKDIR="$HOME/provbee";fi
  if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi

# Host IP check
  if [ "$HOSTIP" = "" ]; then
    if [ $UNAMECHK = "Darwin" ]; then
      eth_name=$(netstat -nr|grep default|head -n1|grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|awk '{print $NF}')
  		HOSTIP=$(ifconfig ${eth_name}|grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| awk -F " " '{print $2}')
  	else
      eth_name=$(ip r | grep default|head -n1|awk '{print $5}')
      HOSTIP=$(ip a show dev ${eth_name}|grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk -F " " '{print $2}'|awk -F "/" '{print $1}')
  	fi
  fi
>>>>>>> installer:install/provbee_new.sh

# SSH KEY Create
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
systemchk


### K3s Install 
k3s_install(){
  info "K3s check & install"
  curl -sL ${INST_SRC}/install/provbee_k3s.sh -o ${TMP_DIR}/provbee_k3s.sh
  chmod +x ${TMP_DIR}/provbee_k3s.sh
  source ${TMP_DIR}/provbee_k3s.sh
  info "K3s checked"
}


### KUBERNETES
kubernetes(){
  PATH=/usr/local/bin:$PATH
  KU_CMD=$(command -v kubectl)
  if [ "$KU_CMD" = "" ]; then fatal "Kubectl run failed!, Your command server check plz."; fi
  if [ "$($KU_CMD version --short | grep Server | wc -l)" -eq 0 ]; then warn "kubernetes cluster check plz."; fatal "chkeck : \$cat ~/.kube/config"; fi 

# Kubernetes deploy
  curl -sL ${INST_SRC}/install/provbee_kubernetes.sh -o ${TMP_DIR}/provbee_kubernetes.sh
  chmod +x ${TMP_DIR}/provbee_kubernetes.sh
  source ${TMP_DIR}/provbee_kubernetes.sh

# done
provbee_banner " ⛵ Enjoy NexClipper! :) "
}


### First Banner
provbee_banner(){
  print_char=$1
  if [ "$print_char" = "" ]; then print_char=" ｡･ﾟﾟ･(>д<)･ﾟﾟ･｡ ";fi 
  print_run=0
  while [ $print_run != ${#print_char} ]
  do
    echo -en "\a\033[92m${print_char:$print_run:1}\033[0m";sleep 0.1;print_run=$((print_run+1))
  done
  echo ""
}


case $K_PLATFORM in 
  kubernetes|baremetal) 
    if [[ $K3S_SET =~ ^([yY][eE][sS]|[yY])$ ]]; then k3s_install; fi
    kubernetes ;;
  nomad) 
    nomad ;;
  openstack) 
    openstack;;
  help|*) 
    fatal "install scripts checking plz";;
esac 
