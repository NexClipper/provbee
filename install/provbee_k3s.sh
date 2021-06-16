#!/bin/bash
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