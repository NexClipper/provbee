#!/bin/bash
cputype(){
  if [ -z "$ARCH" ]; then ARCH=$(uname -m);fi
  case $ARCH in
    amd64|x86_64) CPUARCH=amd64 ;CPUARCH_TOBS="x86_64";;
    aarch64|arm|arm64) CPUARCH=arm64 ;CPUARCH_TOBS="arm64";;
    *) echo ":(";exit 1 ;;
    esac
}
cputype
toolfile="/usr/bin/"

## Terraform Download ##
echo "Terraform Download"
curl -LO `curl -sL "https://www.terraform.io/downloads.html" | grep $CPUARCH | grep linux | awk -F "\"" '{print $2}'` && \
unzip -o terraform*.zip && rm -rf terraform*.zip && \
chmod +x terraform && mv terraform $toolfile

### KubeCTL Download ##
echo "KubeCTL Download"
curl -LO https://dl.k8s.io/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/$CPUARCH/kubectl && \
chmod +x kubectl && mv kubectl $toolfile

## Helm v3 Download ##
echo "Helm Download"
curl -LO `curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-$CPUARCH |head -n1|awk -F"\"" '{print $2}'` && \
tar zxfp helm*.tar.gz && \
chmod +x linux-$CPUARCH/helm && mv linux-$CPUARCH/helm $toolfile && \
rm -rf helm*.tar.gz linux-$CPUARCH

## tobs Download ##
#RUN curl -LO https://github.com/`curl -sL https://github.com/timescale/tobs/releases | egrep -v 'rc|beta|v2'| grep Linux | grep $CPUARCH_TOBS | head -n1 | awk -F"\"" '{print $2}'`  && \
echo "tobs Download"
curl -LO https://github.com/timescale/tobs/releases/download/0.3.0/tobs_0.3.0_Linux_$CPUARCH_TOBS  && \
chmod +x tobs* && mv tobs* ${toolfile}tobs


########################### zip!
#cd /tmp/zzz
#filechk=`ls`
#tar zcvfp provbee_tools.tar.gz $filechk
#rm -rf $filechk