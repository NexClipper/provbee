#!/bin/bash
UNAMECHK=`uname`
KUBENAMESPACE="nex-system"
KUBESERVICEACCOUNT="nexc"
## Provbee, Klevr-agent img ##
if [[ $TAGPROV == "" ]]; then TAGPROV="latest" ; fi
if [[ $TAGKLEVR == "" ]]; then TAGKLEVR="latest" ; fi
if [[ $K_API_KEY == "" ]] || [[ $K_PLATFORM == "" ]] || [[ $K_MANAGER_URL == "" ]] || [[ $K_ZONE_ID == "" ]]; then
    echo "NexClipper Console Page's install script check"
    echo "bye~~"
    exit 1
fi

### console connection check
nexconsolechk(){
urltest="curl -o /dev/null --silent --head --write-out '%{http_code}' ${K_MANAGER_URL}/swagger/doc.json --connect-timeout 3"
if $urltest &>/dev/null ; then
	printf "%s\n" "NexClipper serivce first checking"
else
	printf "%b%s\n" "\033[91m$K_MANAGER_URL\033[0m Not connection. check your network"
  if [[ $DELTEST == "" ]]; then exit 1; fi
fi
}
nexconsolechk



### System check
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

#kube config file secert
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

##################### First Banner
info "Welcome to NexClipper!"
############################################### kubectl command RUN
#info #namespace, serviceaccount create
curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/install/yaml/provbee-00.yaml \
|sed -e $SED_NS -e $SED_SVCAC \
|kubectl apply -f -

#info '### sample ssh secret'
kubectl -n $KUBENAMESPACE create secret generic $KUBESERVICEACCOUNT-ssh-key --from-file=pubkey=$WORKDIR/.ssh/id_rsa.pub --from-file=prikey=$WORKDIR/.ssh/id_rsa --from-file=conf=$WORKDIR/.ssh/config

#info '### Secret??? create'
curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/install/yaml/provbee-01.yaml \
|sed -e $SED_NS -e $SED_SVCAC -e $SED_K_API -e $SED_K_ZID \
|kubectl apply -f - 

#info kubeconfig gen
kubeconfig_gen

############# Provbee-Deployment & Service
curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/install/yaml/provbee-90.yaml \
|sed -e $SED_NS -e $SED_SVCAC -e $SED_TAG_P \
|kubectl apply -f - 

########## Klevr-agent Deamonset
curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/install/yaml/provbee-91.yaml \
|sed -e $SED_NS -e $SED_SVCAC -e $SED_TAG_K -e $SED_K_API -e $SED_K_PLT -e $SED_K_MURL -e $SED_K_ZID \
|kubectl apply -f - 

########## Webstork
#curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/install/yaml/webstork.yaml \
#|sed -e $SED_NS -e $SED_SVCAC \
#|kubectl apply -f - 

#######################################
fi ######## kubectl command END

##########################################
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


#################################################################
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
provbee_banner
