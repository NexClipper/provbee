#!/bin/bash

############################################### K3s 
k3s_install() {
#Host IP Check
if [[ $HOSTIP == "" ]]; then
	HOSTIP=$(ip a | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|awk -F "/" '{print $1}'|head -n1)
fi
if [[ $KUBEUSER == "" ]]; then KUBEUSER="ptr"; fi
if [[ $KUBENS == "" ]]; then KUBENS="default"; fi

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
curl -sfL https://get.k3s.io | K3S_URL=https://$HOSTIP:6443 K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token) sh -

}
#########################################################################
if [[ $K3S_INST =~ ^([yY][eE][sS]|[yY])$ ]]; then echo "ZZZZZZZZZZ"; fi

## kube.config file gen
kubeconfig_gen() {
	git clone https://github.com/ddiiwoong/kubeconfig-generator.git
	apt-get install jq -y
	cd kubeconfig-generator
	./kubeconfig.sh $KUBEUSER $KUBENS
	sed -i "/    server: https:/ c\    server: https:\/\/$HOSTIP:6443" /tmp/kube/k8s-$KUBEUSER-$KUBENS-conf
	cp -Rfvp /tmp/kube/k8s-$KUBEUSER-$KUBENS-conf ../
}
#kubeconfig_gen

#git clone https://github.com/NexClipper/klevry-deploy
#kubectl apply -f ./klevry-deploy/00-namespace.yaml

kubectl apply -f https://raw.githubusercontent.com/NexClipper/klevry-deploy/master/00-namespace.yaml?token=AGEQNG24A6J2HBC7PHOQODK7HYLDS


