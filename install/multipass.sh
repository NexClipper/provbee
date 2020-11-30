#!/bin/bash
UNAMECHK=`uname`
######################################################################################
if [[ $UNAMECHK == "Darwin" ]]; then
#OSX
	if [[ $WORKDIR == "" ]]; then WORKDIR="$HOME/pbmp"; fi
elif [[ $UNAMECHK == "Linux" ]]; then 
#Linux
	if [[ $WORKDIR == "" ]]; then WORKDIR="$HOME/pbmp"; fi
else
	echo ""
fi

######################################################################################
info(){ echo -e '\033[92m[INFO]  \033[0m' "$@";}
warn(){ echo -e '\033[93m[WARN] \033[0m' "$@" >&2;}
fatal(){ echo -e '\033[91m[ERR-] \033[0m' "$@" >&2;exit 1;}
#######################################################################################
with_provbee(){
## Provbee, Klevr-agent img ##
if [[ $TAGPROV != "" ]]; then TAGPROV="TAGPROV=\"${TAGPROV}\""; fi
if [[ $TAGKLEVR != "" ]]; then TAGKLEVR="TAGKLEVR=\"${TAGKLEVR}\""; fi
if [[ $K3S_SET != "" ]]; then K3S_SET="K3S_SET=\"${K3S_SET}\""; fi
if [[ $K_API_KEY == "" ]] || [[ $K_PLATFORM == "" ]] || [[ $K_MANAGER_URL == "" ]] || [[ $K_ZONE_ID == "" ]]; then
    warn "NexClipper Console Page's install script check"
    fatal "bye~~"
fi
}

#######################################################################################
#WorkDir create
if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
#######################################################################################
#######################################################################################
##Linux sudo auth check
sudopermission(){
if SUDOCHK=$(sudo -n -v 2>&1);test -z "$SUDOCHK"; then
    SUDO=sudo
    if [ $(id -u) -eq 0 ]; then SUDO= ;fi
else
	fatal "root permission required"
fi
##OS install package mgmt check
pkgchk
}
##OSX timeout command : brew install coreutils
#######################################################################################


##Host IP Check
hostipcheck(){
if [[ $HOSTIP == "" ]]; then
	if [[ $UNAMECHK == "Darwin" ]]; then
		HOSTIP=$(ifconfig | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|head -n1)
	else
		HOSTIP=$(ip a | grep "inet " | grep -v  "127.0.0.1" | awk -F " " '{print $2}'|awk -F "/" '{print $1}'|head -n1)
	fi
fi
}

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


##OSX brew Install
osxbrew(){
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
}

##CentOS Snap Install
centosnap(){
	################### SNAP find chk
	
$SUDO yum install epel-release -y
$SUDO yum install snapd -y 
$SUDO systemctl enable --now snapd.socket
$SUDO systemctl restart snapd
$SUDO ln -s /var/lib/snapd/snap /snap
#echo "PATH=/var/lib/snapd/snap/bin:/snap/bin:$PATH"
#echo "⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ run shell"
info "export PATH=/snap/bin:\$PATH" | $SUDO tee -a /etc/profile > /dev/null
}

##multipass Install START
multipass_snap(){
if [ $(snap list multipass|wc -l) -eq 0 ]; then
	$SUDO snap install multipass
fi
}
multipass_brew(){
	if [ $(brew list --cask|grep multipass|wc -l) -eq 1 ]; then
		warn "Warning: Cask 'multipass' is already installed."
		info `brew cask info multipass`
	else
		brew cask install multipass
		brew install bash-completion
	fi
#	multipass version
}
##multipass Install END

## Auto Provisioning
auto_provbee_install(){
info "Provbee Start"
with_provbee
provbee_install="curl -sL gg.gg/provbee | $TAGPROV $TAGKLEVR $K3S_SET K_API_KEY=\"${K_API_KEY}\" K_PLATFORM=\"${K_PLATFORM}\" K_MANAGER_URL=\"${K_MANAGER_URL}\" K_ZONE_ID=\"${K_ZONE_ID}\" bash"
multipass launch focal --name multipass-provbee --cpus 2 --mem 2G --disk 10G --cloud-init ~/cloud-init.yaml 
}


########################################

case $UNAMECHK in
	Darwin)
		multipass_brew
		;;
	Linux)
		sudopermission
		multipass_snap
		;;
	*)
		echo "TEST"
		;;
esac

############### TEST
hostipcheck
info $HOSTIP

#echo "PATH=/var/lib/snapd/snap/bin:/snap/bin:$PATH"
#echo "⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ run shell"
info "export PATH=/snap/bin:\$PATH"
################################33
#DEL
#brew cask uninstall multipass
#brew cask zap multipass # to destroy all data, too
###########################################################################

if [[ $AUTO_PRB =~ ^([yY][eE][sS]|[yY])$ ]]; then auto_provbee_install ; fi
###################################
########################⬇
if [[ $provbee_install == "" ]]; then provbee_install="curl zxz.kr"; fi
#### multipass default-set file
cat << EOF > ~/cloud-init.yaml
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqlk5SGQup4AhPZC36HkABrPlwGTs28ZkipOS3kiFRFVVu45yqOXy7sAhadsxDWPVJ+cacWGP9YfkDrwGFifYFGpKPRiZIBD+IoMhxq15fIYmUtSYfO9YbE3qsR4GXq8OB509O9qDItHaVKAtKymMbRN/z0hnHjyU1hmKwK9f7lEMe7JDK8QycXjBd/2xfSc//J3129r3+O7Ia/WcWnJGR3bbRUaQehTRfU+h12o5kbNaBOxqqyqPkBKC1hSn4zyn02prRLX798fWr07yNmUgMZETDjovjG/lsWxcA4kaZFEBRHXEJoJp/AaM5gyoAnOnSrAIN6Vax77/e+6U3Lt/EcNdFGy2MQBt4AQW/b/J/UERrdh22vCfCkJsRBolqHYqdsexy2E/G3wo6CWhmpkUx5IxcU32kbxlS0EnPd8TV1hR653YlZrH9PXYyy5GwERnvx63YAphcD7xaqgvWFmVumDZkCQcQt1uYR0wO0V4ynwNmji92nCWGIeUuYAMugjjXF7AnW9Tm+i7iDJB7oZ3s87VrWpr5cdWXdI1VFfn898kJllzRfW4FQIKD3VLJIJrwjm42CLCJRCzoWJIqhcTlo3+8PPt1cGudRmOsGWBdHNhWqbgA6UzYKUK1hG8A6LtIQqyr1M8ccEhWi99PmuYskOuyNpQf2NHOg5jNOL3Kmw== zzz@NexCloud
package_update: true
packages:
 - curl
 - jq
 - git
write_files:
  - content: |-
    owner: ubuntu:ubuntu
    path: /home/ubuntu/file.txt
    permissions: '0644'
bootcmd:
  - echo $(whoami) > /root/boot.txt
runcmd:
  - $provbee_install
EOF
info "⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ multipass test(default focal 20.04)"
info "multipass launch focal --name multipass-provbee --cpus 2 --mem 2G --disk 10G --cloud-init ~/cloud-init.yaml"

################
#apt install -y libvirt-daemon-driver-qemu qemu-kvm qemu-system libvirt-daemon-system
#qemu-kvm libvirt-clients bridge-utils virt-manager
#echo "Y" > /sys/module/kvm/parameters/ignore_msrs
##qemu-kvm-core.x86_64 qemu-kvm.x86_64 #qemu-kvm-common.x86_64
#libvirt-daemon-kvm.x86_64 mkisofs
#yum install libvirt-devel
#systemctl stop NetworkManager
