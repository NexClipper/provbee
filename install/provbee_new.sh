#!/bin/bash
UNAMECHK=`uname`
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
#INST_SRC="https://raw.githubusercontent.com/NexClipper/provbee/master"
INST_SRC="https://raw.githubusercontent.com/NexClipper/provbee/installer"
PATH=/usr/local/bin:$PATH
KU_CMD=$(command -v kubectl)
TMP_DIR=$(mktemp -d -t provbee-inst.XXXXXXXXXX)
################ TEMP
K_PLATFORM="kubernetes"

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

##Linux sudo auth check
#sudopermission(){
#if SUDOCHK=$(sudo -n -v 2>&1);test -z "$SUDOCHK"; then
#    SUDO=sudo
#    if [ $(id -u) -eq 0 ]; then SUDO= ;fi
#else
#	echo "root permission required"
#	exit 1
#fi
###OS install package mgmt check
#pkgchk
#}
###OSX timeout command : brew install coreutils
### package cmd Check
#pkgchk(){
#	LANG=en_US.UTF-8
#	yum > /tmp/check_pkgmgmt 2>&1
#	if [[ `(grep 'yum.*not\|not.*yum' /tmp/check_pkgmgmt)` == "" ]];then
#		centosnap
#	#else
#		#Pkg_mgmt="apt-get"
#		#apt update
#	fi
#}
#

### K3s Install check
if [[ $K3S_SET =~ ^([yY][eE][sS]|[yY])$ ]]; then
  curl -sL ${INST_SRC}/install/provbee_k3s.sh -o ${TMP_DIR}/provbee_k3s.sh
  chmod +x ${TMP_DIR}/provbee_k3s.sh
  source ${TMP_DIR}/provbee_k3s.sh

fi


### BAREMATAL
#if [[ $K_PLATFORM == "baremetal" ]]; then
#	info "baremetal install"
#  info "curl zzz.kr/docker|bash ............ Docker install test" 
#  ##temp
#fi

### KUBERNETES
if [[ $K_PLATFORM == "kubernetes" ]]; then
  if [ "$KU_CMD" = "" ]; then fatal "Kubectl run failed!, Your command server check plz."; fi
  if [ "$($KU_CMD version --short | grep Server | wc -l)" -eq 0 ]; then warn "kubernetes cluster check plz."; fatal "chkeck : \$cat ~/.kube/config"; fi 
################################


### Kubernetes deploy
  curl -sL ${INST_SRC}/install/provbee_kubernetes.sh -o ${TMP_DIR}/provbee_kubernetes.sh
  chmod +x ${TMP_DIR}/provbee_kubernetes.sh
  source ${TMP_DIR}/provbee_kubernetes.sh





fi ######## kubectl command END

##########################################

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
######################################################################END LINE
######banner
provbee_banner(){
if [ -t 1 ]; then
  RB_YELLOW=$(printf '\033[38;5;226m')
  RB_VIOLET=$(printf '\033[38;5;163m')
  YELLOW=$(printf '\033[33m')
  RESET=$(printf '\033[m')
  RB_RESET=$(printf '\033[0m')
else
  RB_YELLOW=""
  RB_VIOLET=""
  YELLOW=""
  RB_RESET=""
fi
printf "%s88888888ba  %s            %s             %s             %s 88888888ba  %s                        %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
printf "%s88      '8b %s            %s             %s             %s 88      '8b %s                        %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
printf "%s88      ,8P %s            %s             %s             %s 88      ,8P %s                        %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
printf "%s88aaaaaa8P' %s 🐝,dPPYba, %s  ,adPPYba,  %s 8b       d8 %s 88aaaaaa8P' %s  ,adPPYba,   ,adPPYba, %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
printf "%s88'''''''   %s 88P'   'Y8 %s a8'     '8a %s '8b     d8' %s 88''''''8b, %s a8P_____88  a8P_____88 %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
printf "%s88          %s 88         %s 8b       d8 %s  '8b   d8'  %s 88      '8b %s 8PP'''''''  8PP''''''' %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
printf "%s88          %s 88         %s '8a,   ,a8' %s   '8b,d8'   %s 88      a8P %s '8b,   ,aa  '8b,   ,aa %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
printf "%s88          %s 88         %s  ''YbbdP''  %s     '8'     %s 88888888P'  %s  ''Ybbd8''   ''Ybbd8'' %s\n" $YELLOW $YELLOW $YELLOW $YELLOW $RB_YELLOW $YELLOW $RB_RESET
     

}


provbee_banner
