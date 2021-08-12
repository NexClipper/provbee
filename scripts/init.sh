#!/bin/bash
echo ">> directory create"
mkdir -p /root/.ssh/ $WKDIR/provbee /tmp/zzz ~/.terraform.d/plugins/ $WKDIR/terraform_state ~/.kube/

echo ">> ssh config create"
echo "Host *
	StrictHostKeyChecking no
	UserKnownHostsFile /dev/null" > /root/.ssh/config

#####################	
echo ">> shell scripts file copy"
shdir="/tmp/scripts"
cp -Rfp $shdir/provider.sh /usr/bin/tfprovider
cp -Rfp $shdir/beecmd /usr/bin/beecmd
cp -Rfp $shdir/busybee.sh /usr/bin/busybee
cp -Rfp $shdir/get_pubkey.sh /usr/local/bin/get_pubkey.sh
cp -Rfp $shdir/tools.sh /tools.sh

echo "root:dkdhajfldkvmek!" | chpasswd

echo ">> tools download"
bash /tools.sh
rm -rf $shdir


# ssh setting
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.ori; \
#sed -e "s|[#]*AuthorizedKeysCommand none|AuthorizedKeysCommand /usr/local/bin/get_pubkey.sh|g" \
#    -e "s|[#]*AuthorizedKeysCommandUser nobody|AuthorizedKeysCommandUser nobody|g" \
sed -e "s|[#]*PermitRootLogin prohibit-password|PermitRootLogin yes|g" \
    -e "s|[#]*UsePAM yes|UsePAM no|g" \
    -e "s|[#]*PermitUserEnvironment no|PermitUserEnvironment no|g" \
    -e "s|[#]*PubkeyAuthentication yes|PubkeyAuthentication yes|g" \
    /etc/ssh/sshd_config.ori > /etc/ssh/sshd_config;

sed -i 's/cgroup_add_service$/echo "NexClipper" #cgroup_add_service#/g' /lib/rc/sh/openrc-run.sh
