#!/bin/bash
## information
info(){ echo -e '\033[92m[INFO]  \033[0m' "$@";}
warn(){ echo -e '\033[93m[WARN] \033[0m' "$@" >&2;}
fatal(){ echo -e '\033[91m[ERROR] \033[0m' "$@" >&2;exit 1;}
echo $(date "+%Y%m%d_%H%M%S") "|" "== Provbee start ==" >> /tmp/busybee.log
#####################################################
#Terraform Download
terraformdownload(){
	TERRAVERSIONCHK=$(curl -s https://releases.hashicorp.com/terraform/|grep -Ev "rc|beta|alpha|oci" |grep "/terraform/"|grep $TERRAVERSION |awk -F"\"" '{print $2}')
	if [[ $TERRAVERSIONCHK == "" ]]; then
		info "Version checking plz : $TERRAVERSION"
		info "Version info (now) : "
		terraform version
	else
		TERRADOWN=$(curl -sL https://releases.hashicorp.com$TERRAVERSIONCHK|grep "linux_amd64"|cut -d "\"" -f 10)
		curl -LO https://releases.hashicorp.com$TERRADOWN
		unzip terraform*.zip && rm -rf terraform*.zip
		mv terraform /usr/bin/
	fi
}

#KubeCTL Download
kubectldownload(){
	KUCTLVERSIONCHK=$(curl -sL -o /tmp/kubectl -w "%{http_code}" https://storage.googleapis.com/kubernetes-release/release/$KUCTLVERSION/bin/linux/amd64/kubectl)
	if [[ $KUCTLVERSIONCHK -eq 200 ]]; then 
		#curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUCTLVERSION/bin/linux/amd64/kubectl
		chmod +x /tmp/kubectl
		mv /tmp/kubectl /usr/bin/
	else
		info "Version checking plz : $KUCTLVERSION"
		info "Version info (now) : "
		kubectl version -o yaml
	fi
}

#Helm Download
helmdownload(){
	HELMVERIONCHK=$(curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-amd64|grep $HELMVERSION |head -n1|awk -F"\"" '{print $2}')
	if [[ $HELMVERIONCHK != "" ]]; then
		curl -LO `curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-amd64|grep $HELMVERSION |head -n1|awk -F"\"" '{print $2}'`
		tar zxfp helm*.tar.gz 
		chmod +x linux-amd64/helm 
		mv linux-amd64/helm /usr/bin/helm
		rm -rf helm*.tar.gz linux-amd64
	else
		info "Version checking plz : $HELMVERSION"
        info "Version info (now) : "
		helm version
	fi
}

###########################CONFIG
#kube_config check
KUBECONFIGFILE="$HOME/.kube/config"
if [[ $KUBESERVICEACCOUNT == "" ]]; then KUBESERVICEACCOUNT="nexc"; fi 
kubeconfig(){
kubectl get secrets $KUBESERVICEACCOUNT-kubeconfig -o jsonpath='{.data.kubeconfig}' > $KUBECONFIGFILE.base64 2>/tmp/err_kubeconfig.log
if [ -s ${KUBECONFIGFILE}.base64 ]; then
	cat ${KUBECONFIGFILE}.base64 | base64 -d > ${KUBECONFIGFILE}
  	rm -rf ${KUBECONFIGFILE}.base64 
	info "$KUBECONFIGFILE created" 
else
    fatal "$(cat /tmp/err_kubeconfig.log)"
fi
}


if [ ! -s $KUBECONFIGFILE ]; then warn "Not Found $KUBECONFIGFILE"; kubeconfig;fi 
if [[ $TERRAVERSION != "" ]]; then terraformdownload;fi
if [[ $KUCTLVERSION != "" ]]; then kubectldownload;fi 
if [[ $HELMVERSION != "" ]]; then helmdownload; fi


#if [ -f /data/klevry/kube-config ]; then cp -Rfvp /data/klevry/kube-config ~/.kube/config; fi

##ssh start
/etc/init.d/sshd --dry-run start
/etc/init.d/sshd start

##waiting test
#tail -F anything 
#exec "$@"
tail -F /tmp/busybee.log
