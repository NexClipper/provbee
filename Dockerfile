FROM alpine:latest 
#alpine:3.12.3 - 2020.12.31
LABEL maintainer="NexCloud Peter <peter@nexclipper.io>"

RUN apk add --no-cache --update git bash unzip curl openssh-server openssh-client openrc jq
#RUN apk add --no-cache --update gcc musl-dev make openssh-keygen
#RUN apk add --no-cache --update curl unzip openssh-server openrc jq bash
ENV TF_DEV=true
ENV TF_RELEASE=1

## WorkDIR & tmpDIR make
#RUN mkdir -p /data/tmp && mkdir -p ~/.terraform.d/plugins/
ENV WKDIR=/data
ENV PATH /usr/local/bin:$PATH
RUN mkdir -p $WKDIR/klevry /tmp/zzz ~/.terraform.d/plugins/ $WKDIR/terraform_state ~/.kube/

### latest version download ###
## Terraform Download ##
RUN curl -LO `curl -sL "https://www.terraform.io/downloads.html" | grep amd64 | grep linux | awk -F "\"" '{print $2}'` && \
    unzip -o terraform*.zip && rm -rf terraform*.zip && \
    chmod +x terraform && mv terraform /usr/bin/

## KubeCTL Download ##
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x kubectl && mv kubectl /usr/bin/

## Helm v3 Download ##
RUN curl -LO `curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-amd64 |head -n1|awk -F"\"" '{print $2}'` && \
    tar zxfp helm*.tar.gz && \
    chmod +x linux-amd64/helm && mv linux-amd64/helm /usr/bin/ && \
    rm -rf helm*.tar.gz linux-amd64

## tobs Download ##
#RUN curl -LO https://github.com/`curl -sL https://github.com/timescale/tobs/releases | egrep -v 'rc|beta|v2'| grep Linux | grep x86 | head -n1 | awk -F"\"" '{print $2}'`  && \
RUN curl -LO https://github.com/timescale/tobs/releases/download/0.2.1/tobs_0.2.1_Linux_x86_64  && \
    chmod +x tobs* && mv tobs* /usr/bin/tobs

COPY .ssh /root/.ssh
COPY entrypoint.sh /entrypoint.sh
COPY ./scripts/provider.sh /usr/bin/tfprovider
COPY ./scripts/beecmd /usr/bin/beecmd
COPY ./scripts/busybee.sh /usr/bin/busybee
COPY ./scripts/get_pubkey.sh /usr/local/bin/get_pubkey.sh

# ssh setting
RUN echo "root:dkdhajfldkvmek!" | chpasswd
RUN mv /etc/ssh/sshd_config /etc/ssh/sshd_config.ori; \
sed -e "s|[#]*AuthorizedKeysCommand none|AuthorizedKeysCommand /usr/local/bin/get_pubkey.sh|g" \
    -e "s|[#]*AuthorizedKeysCommandUser nobody|AuthorizedKeysCommandUser nobody|g" \
    -e "s|[#]*PermitRootLogin prohibit-password|PermitRootLogin yes|g" \
    -e "s|[#]*UsePAM yes|UsePAM no|g" \
    -e "s|[#]*PermitUserEnvironment no|PermitUserEnvironment no|g" \
    -e "s|[#]*PubkeyAuthentication yes|PubkeyAuthentication yes|g" \
    /etc/ssh/sshd_config.ori > /etc/ssh/sshd_config;
RUN sed -i 's/cgroup_add_service$/echo "NexClipper" #cgroup_add_service#/g' /lib/rc/sh/openrc-run.sh
RUN rc-update add sshd; mkdir /run/openrc && touch /run/openrc/softlevel; rc-status

WORKDIR	$WKDIR
#ENTRYPOINT ["/entrypoint.sh"]
#CMD ["/bin/sh"]
CMD ["/bin/bash", "/entrypoint.sh"]

#ENTRYPOINT ["terraform"]
