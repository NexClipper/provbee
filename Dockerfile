FROM golang:alpine AS installer
LABEL maintainer="NexCloud Peter <peter@nexclipper.io>"

RUN apk add --update git bash openssh  unzip gcc curl cdrkit musl-dev make
ENV TF_DEV=true
ENV TF_RELEASE=1

## WorkDIR & tmpDIR make
#RUN mkdir -p /data/tmp && mkdir -p ~/.terraform.d/plugins/
ENV WKDIR=/data
RUN mkdir -p $WKDIR /tmp/zzz ~/.terraform.d/plugins/ /terraform_state


### Default Terraform & KubeCTL latest version download ###
## Terraform Download ##
RUN curl -o $WKDIR/terraform.zip $(curl -sL "https://www.terraform.io/downloads.html" | grep amd64 | grep linux | awk -F "\"" '{print $2}') && \
    unzip -o $WKDIR/terraform.zip && rm -rf $WKDIR/terraform.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin/

## KubeCTL Download ##
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl


COPY .ssh /root/.ssh
COPY entrypoint.sh /entrypoint.sh
copy provider.sh /provider.sh

WORKDIR	$WKDIR
CMD ["/bin/bash", "/entrypoint.sh"]
#ENTRYPOINT ["terraform"]
