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
    warn "K3s Install fail."
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

k3s_checking

### K3s User permission Checking!
K3SPERM=$($KU_CMD cluster-info 2>&1 | grep -E "k3s.*permission"|wc -l)
if [ $K3SPERM -eq 0 ]; then
  if [[ $($KU_CMD get node -o jsonpath='{.items[*].metadata.managedFields[*].manager}') == "k3s" ]]; then
    if [ $(id -u) -ne 0 ]; then fatal "run as root user" ; fi
  fi
else    
  fatal "run as root user"
fi