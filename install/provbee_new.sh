#!/bin/bash
UNAMECHK=`uname`
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
#INST_SRC="https://raw.githubusercontent.com/NexClipper/provbee/master"
INST_SRC="https://raw.githubusercontent.com/NexClipper/provbee/installer"
TMP_DIR=$(mktemp -d -t provbee-inst.XXXXXXXXXX)

## information
info(){ echo -e '\033[92m[INFO]  \033[0m' "$@";}
warn(){ echo -e '\033[93m[WARN] \033[0m' "$@" >&2;}
fatal(){ echo -e '\033[91m[ERROR] \033[0m' "$@" >&2;exit 1;}
######################################################################################

###  ##
default_chk(){
# Provbee, Klevr-agent img  
  if [[ $TAGPROV == "" ]]; then TAGPROV="latest" ; fi
  if [[ $TAGKLEVR == "" ]]; then TAGKLEVR="latest" ; fi
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
  if [[ $HOSTIP == "" ]]; then
  	if [[ $UNAMECHK == "Darwin" ]]; then
      eth_name=$(netstat -nr|grep default|head -n1|grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|awk '{print $NF}')
  		HOSTIP=$(ifconfig $eth_name | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| awk -F " " '{print $2}')
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



### K3s Install check
if [[ $K3S_SET =~ ^([yY][eE][sS]|[yY])$ ]]; then
  curl -sL ${INST_SRC}/install/provbee_k3s.sh -o ${TMP_DIR}/provbee_k3s.sh
  chmod +x ${TMP_DIR}/provbee_k3s.sh
  source ${TMP_DIR}/provbee_k3s.sh
fi


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
}



#################################################################
#provbee run chk
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


case $K_PLATFORM in 
echo $K_PLATFORM
  kubernetes|baremetal) kubernetes ;;
  nomad) nomad ;;
  openstack) openstack;;
  help|*) fatal "install scripts checking plz";;
esac 