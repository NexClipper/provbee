FROM golang:alpine AS installer
LABEL maintainer="NexCloud Peter <peter@nexclipper.io>"

RUN apk add --update git bash unzip gcc curl musl-dev make
ENV TF_DEV=true
ENV TF_RELEASE=1

## WorkDIR & tmpDIR make
#RUN mkdir -p /data/tmp && mkdir -p ~/.terraform.d/plugins/
ENV WKDIR=/data
RUN mkdir -p $WKDIR /tmp/zzz ~/.terraform.d/plugins/ $WKDIR/terraform_state


### Default Terraform & KubeCTL latest version download ###
## Terraform Download ##
RUN curl -LO `curl -sL "https://www.terraform.io/downloads.html" | grep amd64 | grep linux | awk -F "\"" '{print $2}'` && \
    unzip -o terraform*.zip && rm -rf terraform*.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin/

## KubeCTL Download ##
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/

## Helm v3 Download ##
RUN curl -LO `curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-amd64 |head -n1|awk -F"\"" '{print $2}'` && \
    tar zxvfp helm*.tar.gz && rm -rf helm*.tar.gz && \
    chmod +x linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/

COPY .ssh /root/.ssh
COPY entrypoint.sh /entrypoint.sh
copy provider.sh /provider.sh

WORKDIR	$WKDIR
CMD ["/bin/bash", "/entrypoint.sh"]
#ENTRYPOINT ["terraform"]
