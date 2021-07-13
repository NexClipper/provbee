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

#K3s Server Install scripts
k3s_install() {
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 " sh -s - server --bind-address $HOSTIP
#--datastore-endpoint "mysql://nex:nexcloud@tcp(db.zxz.kr:3306)/k3s"
PATH=/usr/local/bin:$PATH
KU_CMD=$(command -v kubectl)
}

k3s_checking

#### K3s User permission Checking!
#K3SPERM=$($KU_CMD cluster-info 2>&1 | grep -E "k3s.*permission"|wc -l)
#if [ $K3SPERM -eq 0 ]; then
#  if [[ $($KU_CMD get node -o jsonpath='{.items[*].metadata.managedFields[*].manager}') == "k3s" ]]; then
#    if [ $(id -u) -ne 0 ]; then fatal "run as root user" ; fi
#  fi
#else    
#  fatal "run as root user"
#fi
