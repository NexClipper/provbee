#!/bin/bash
UNAMECHK=`uname`
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
INST_SRC="https://raw.githubusercontent.com/NexClipper/provbee/master"
TMP_DIR=$(mktemp -d -t provbee-inst.XXXXXXXXXX)
PATH=/usr/local/bin:$PATH

## information
info(){ echo -e '\033[92m[INFO]  \033[0m' "$@";}
warn(){ echo -e '\033[93m[WARN] \033[0m' "$@" >&2;}
fatal(){ echo -e '\033[91m[ERROR] \033[0m' "$@" >&2;exit 1;}
######################################################################################

### default check
default_chk(){
# Provbee, Klevr-agent tag check
  if [[ $TAGPROV == "" ]]; then TAGPROV="latest" ; else info "Provbee Image Tag : $TAGPROV ";fi
  if [[ $TAGKLEVR == "" ]]; then TAGKLEVR="latest" ; else info "Klevr Image Tag : $TAGKLEVR ";fi

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
  KU_CMD=$(command -v kubectl)
  if [ "$KU_CMD" = "" ]; then fatal "K3s not installed, Reinstall k3s plz."; fi
  info "K3s checked"
}


### KUBERNETES
kubernetes(){
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
