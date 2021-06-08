#!/bin/bash
BEE_INFO="from_ip"
apikeychk(){
if [ -f /tmp/whoisapi ]; then OPENAPIKEY=$(cat /tmp/whoisapi)
else OPENAPIKEY=$(curl -sL https://raw.githubusercontent.com/NexClipper/provbee/master/scripts/OPENAPI); echo $OPENAPIKEY > /tmp/whoisapi
fi
}
apikeychk

### External IP connection check
whoisipchk(){
if [ "$IPAddr" = "" ]; then
    IPAddr=$(curl -sL http://ip.nexclipper.io --connect-timeout 3)
else
    IPAddr=$(curl -sL https://checkip.amazonaws.com --connect-timeout 3)
fi
if [ "$IPAddr" = "" ];then fatal "Your IP address checking fail" ; fi
}
if [ "${beeCMD[0]}" = "" ];then whoisipchk ;else IPAddr=${beeCMD[0]};fi


### IP country Code 
IPcountry="http://whois.kisa.or.kr/openapi/ipascc.jsp?query=${IPAddr}&key=${OPENAPIKEY}&answer=json"
countryCode=$(curl -sL $IPcountry)
if [ "$(echo $countryCode|jq -r '.whois.error.error_code')" = "022" ]; then 
	rm -rf /tmp/whoisapi
	apikeychk
	IPcountry="http://whois.kisa.or.kr/openapi/ipascc.jsp?query=${IPAddr}&key=${OPENAPIKEY}&answer=json"
	countryCode=$(curl -sL $IPcountry)
fi 
registryRIRCHK=$(echo $countryCode|jq -r '.whois.registry')
countryCodeCHK=$(echo $countryCode|jq -r '.whois.countryCode')


##### query
if [ "$countryCodeCHK" = "KR" ]; then
	KRURL="http://whois.kisa.or.kr/openapi/whois.jsp?query=${IPAddr}&key=${OPENAPIKEY}&answer=json"
	zzz=$(curl -sL $KRURL)
	whoisNAME=$(echo $zzz|jq -r '.whois.english.ISP.netinfo.servName')
	whoisORG=$(echo $zzz|jq -r '.whois.english.ISP.netinfo.orgName')
else
	if [ "$registryRIRCHK" != "" ]; then
		if [ "$registryRIRCHK" = "ARIN" ]; then whoisCHKurl="https://rdap.arin.net/registry/ip/${IPAddr}"
			zzz=$(curl -sL $whoisCHKurl)
			whoisNAME=$(echo $zzz|jq -r '.name')
			whoisORG=$(echo $zzz|jq '.entities[].vcardArray[1]'|grep -A4 fn|sed -n 4p|sed -e 's/^. *//g' -e 's/"//g')
		elif [ "$registryRIRCHK" = "AFRINIC" ]; then whoisCHKurl="https://rdap.afrinic.net/rdap/ip/${IPAddr}"
			zzz=$(curl -sL $whoisCHKurl)
			whoisNAME=$(echo $zzz|jq -r '.name')
			whoisORG=$(echo $zzz|jq '.entities[].vcardArray[1]'|grep -A4 fn|sed -n 4p|sed -e 's/^. *//g' -e 's/"//g')
		elif [ "$registryRIRCHK" = "APNIC" ]; then whoisCHKurl="https://rdap.apnic.net/ip/${IPAddr}"
			zzz=$(curl -sL $whoisCHKurl)
			whoisNAME=$(echo $zzz|jq -r '.name')
			whoisORG=$(echo $zzz|jq '.entities[].vcardArray[1]'|grep -A4 fn|sed -n 4p|sed -e 's/^. *//g' -e 's/"//g')
		elif [ "$registryRIRCHK" = "LACNIC" ]; then whoisCHKurl="https://rdap.lacnic.net/rdap/ip/${IPAddr}"
			zzz=$(curl -sL $whoisCHKurl)
			whoisNAME=$(echo $zzz|jq -r '.name')
			whoisORG=$(echo $zzz|jq '.entities[].vcardArray[1]'|grep -A4 fn|sed -n 4p|sed -e 's/^. *//g' -e 's/"//g')
		elif [ "$registryRIRCHK" = "RIPENCC" ]; then whoisCHKurl="https://rdap.db.ripe.net/ip/${IPAddr}"
			zzz=$(curl -sL $whoisCHKurl)
			whoisNAME=$(echo $zzz|jq -r '.name')
			whoisORG=$(echo $zzz|jq '.entities[].vcardArray[1]'|grep -A4 fn|sed -n 4p|sed -e 's/^. *//g' -e 's/"//g')
		else
			echo "zzZ!"
		fi
	fi
fi
#printf "%-2s : %-10s %-20s %-30s\n" $countryCodeCHK $registryRIRCHK $whoisNAME "$whoisORG"

##### CSP Search
cspNAME=$(echo $whoisORG|tr '[:upper:]' '[:lower:]')
if [[ $cspNAME =~ ^.*amazon|aws.*$ ]]; then cspNAME="AWS"
    elif [[ $cspNAME =~ ^.*google|gcp.*$ ]]; then cspNAME="GCP"
    elif [[ $cspNAME =~ ^.*naver|nbp.*$ ]]; then cspNAME="NBP"
    elif [[ $cspNAME =~ ^.*oracle|oci.*$ ]]; then cspNAME="OCI"
    else cspNAME="unknown" 
fi
#### IP range TEST
#https://ip-ranges.amazonaws.com/ip-ranges.json
#https://www.gstatic.com/ipranges/cloud.json




##### TOTAL JSON
TYPE_JSON="json"
TOTAL_JSON="{\"EXT_IP\":\"$IPAddr\",\"COUNTRY_CODE\":\"$countryCodeCHK\",\"REGISTRY_RIR\":\"$registryRIRCHK\",\"WHOIS_NAME\":\"$whoisNAME\",\"WHOIS_ORG\":\"$whoisORG\",\"CSP_NAME\":\"$cspNAME\"}"
################Print JSON
beejson(){
if [[ $TYPE_JSON == "json" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[${TOTAL_JSON}]}]}"
elif [[ $TYPE_JSON == "base64" ]] || [[ $TYPE_JSON == "string" ]]; then
  BEE_JSON="{\"provbee\":\"v1\",\"busybee\":[{\"beecmd\":\"$beeA\",\"cmdstatus\":\""${STATUS_JSON}"\",\"beeinfo\":\"${BEE_INFO}\",\"beetype\":\"${TYPE_JSON}\",\"data\":[\""${TOTAL_JSON}"\"]}]}"
else
  BEE_JSON="Bee!"
fi
echo $BEE_JSON
}
beejson