#!/bin/bash

#Terraform Download
if [[ $TERRAVERSION != "" ]]; then
	TERRAVERSIONCHK=$(curl -s https://releases.hashicorp.com/terraform/|grep -Ev "rc|beta|alpha|oci" |grep "/terraform/"|grep $TERRAVERSION |awk -F"\"" '{print $2}')
	if [[ $TERRAVERSIONCHK == "" ]]; then
		echo "Version checking plz : $TERRAVERSION"
		echo "Version info (now) : "
		terraform version
	else
		TERRADOWN=$(curl -sL https://releases.hashicorp.com$TERRAVERSIONCHK|grep "linux_amd64"|cut -d "\"" -f 10)
		curl -LO https://releases.hashicorp.com$TERRADOWN
		unzip terraform*.zip && rm -rf terraform*.zip
		mv terraform /usr/local/bin/
	fi
fi
#KubeCTL Download
if [[ $KUCTLVERSION != "" ]]; then
	KUCTLVERSIONCHK=$(curl -sL -o /tmp/kubectl -w "%{http_code}" https://storage.googleapis.com/kubernetes-release/release/$KUCTLVERSION/bin/linux/amd64/kubectl)
	if [[ $KUCTLVERSIONCHK -eq 200 ]]; then 
		#curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUCTLVERSION/bin/linux/amd64/kubectl
		chmod +x /tmp/kubectl
		mv /tmp/kubectl /usr/local/bin/kubectl
	else
		echo "Version checking plz : $KUCTLVERSION"
		echo "Version info (now) : "
		kubectl version -o yaml
	fi
fi










tail -F anything
