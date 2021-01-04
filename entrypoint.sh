#!/bin/bash
echo $(date "+%Y%m%d_%H%M%S") "|" "== Provbee start ==" >> /tmp/busybee.log
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
		mv terraform /usr/local/bin/ && cp -Rfvp /usr/local/bin/terraform /usr/bin/
	fi
fi

#KubeCTL Download
if [[ $KUCTLVERSION != "" ]]; then
	KUCTLVERSIONCHK=$(curl -sL -o /tmp/kubectl -w "%{http_code}" https://storage.googleapis.com/kubernetes-release/release/$KUCTLVERSION/bin/linux/amd64/kubectl)
	if [[ $KUCTLVERSIONCHK -eq 200 ]]; then 
		#curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUCTLVERSION/bin/linux/amd64/kubectl
		chmod +x /tmp/kubectl
		mv /tmp/kubectl /usr/local/bin/kubectl && cp -Rfvp /usr/local/bin/kubectl /usr/bin/
	else
		echo "Version checking plz : $KUCTLVERSION"
		echo "Version info (now) : "
		kubectl version -o yaml
	fi
fi

#Helm Download
if [[ $HELMVERSION != "" ]]; then
	HELMVERIONCHK=$(curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-amd64|grep $HELMVERSION |head -n1|awk -F"\"" '{print $2}')
	if [[ $HELMVERIONCHK != "" ]]; then
		curl -LO `curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-amd64|grep $HELMVERSION |head -n1|awk -F"\"" '{print $2}'`
		tar zxfp helm*.tar.gz 
		chmod +x linux-amd64/helm 
		mv linux-amd64/helm /usr/local/bin/ && cp -Rfvp /usr/local/bin/helm /usr/bin/
		rm -rf helm*.tar.gz linux-amd64
	elseß
		echo "Version checking plz : $HELMVERSION"
                echo "Version info (now) : "
		helm version
	fi
fi



#if [ -f /data/klevry/kube-config ]; then cp -Rfvp /data/klevry/kube-config ~/.kube/config; fi

##ssh start
/etc/init.d/sshd --dry-run start
/etc/init.d/sshd start

##waiting test
#tail -F anything 
#exec "$@"
tail -F /tmp/busybee.log
