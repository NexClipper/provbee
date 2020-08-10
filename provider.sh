#!/bin/bash
HASHICORPURL="https://releases.hashicorp.com"
PROVIDER=$1
PROVIDER_VER=$2

if [[ $PROVIDER == "" ]]; then echo "Select terraform provider";exit 1; fi

PROVIDER_LIST="/terraform-provider-$1/"

PROVIDER_URN=$(curl -s ${HASHICORPURL} | grep $PROVIDER_LIST | awk -F"\"" '{print $2}')
if [[ $PROVIDER_URN == "" ]]; then echo "Rechecking terraform provider"; exit 1; fi

if [[ $PROVIDER_VER == "" ]]; then 
	PROVIDER_VER=$(curl -s ${HASHICORPURL}${PROVIDER_URN}|grep ${PROVIDER_URN} |awk -F "/" '{print $3}' |head -n1)
else
	PROVIDER_VER=$(curl -s ${HASHICORPURL}${PROVIDER_URN}|grep ${PROVIDER_URN} |awk -F "/" '{print $3}' | grep ^$PROVIDER_VER | grep '^[0-9].*[0-9].[0-9]$'|head -n1)
fi

PROVIDER_DOWNLOAD=$(curl -sL ${HASHICORPURL}${PROVIDER_URN}${PROVIDER_VER} |grep linux_amd64| sed 's/^.*href=//'|sed 's/>.*$//' |sed 's/"//g')

curl -OL ${HASHICORPURL}${PROVIDER_DOWNLOAD} #-i |awk '/[cC]ontent-[lL]ength/{print $2}'
unzip terraform-provider-*.zip && rm -rf terraform-provider-*.zip
mv terraform-provider-* /data/

