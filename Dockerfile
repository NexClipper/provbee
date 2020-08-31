FROM golang:alpine
LABEL maintainer="NexCloud Peter <peter@nexclipper.io>"

RUN apk add --update git bash unzip gcc curl musl-dev make openssh-server openssh-client openssh-keygen openrc
ENV TF_DEV=true
ENV TF_RELEASE=1

## WorkDIR & tmpDIR make
#RUN mkdir -p /data/tmp && mkdir -p ~/.terraform.d/plugins/
ENV WKDIR=/data
ENV PATH /usr/local/bin:$PATH
RUN mkdir -p $WKDIR/klevry /tmp/zzz ~/.terraform.d/plugins/ $WKDIR/terraform_state ~/.kube/ 

## USER create
#RUN useradd zzz & echo "zzz:zzz" | chpasswd

### Default Terraform & KubeCTL latest version download ###
## Terraform Download ##
RUN curl -LO `curl -sL "https://www.terraform.io/downloads.html" | grep amd64 | grep linux | awk -F "\"" '{print $2}'` && \
    unzip -o terraform*.zip && rm -rf terraform*.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin/ && cp -Rfvp /usr/local/bin/terraform /usr/bin/ 

## KubeCTL Download ##
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/ && cp -Rfvp /usr/local/bin/kubectl /usr/bin/

## Helm v3 Download ##
RUN curl -LO `curl -sL https://github.com/helm/helm/releases|egrep -v 'rc|beta|v2'|grep linux-amd64 |head -n1|awk -F"\"" '{print $2}'` && \
    tar zxfp helm*.tar.gz && \
    chmod +x linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/ && cp -Rfvp /usr/local/bin/helm /usr/bin/ && \
    rm -rf helm*.tar.gz linux-amd64

COPY .ssh /root/.ssh
COPY entrypoint.sh /entrypoint.sh
COPY provider.sh /provider.sh
COPY get_pubkey.sh /usr/local/bin/get_pubkey.sh
#COPY nodesearch.sh /nodesearch.sh
COPY provbeecmd.sh /usr/bin/busybee

# ssh setting
#RUN sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
#RUN sed -i 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo "root:dkdhajfldkvmek!" | chpasswd
RUN sed -i 's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
RUN sed -i 's/^#PermitUserEnvironment no/PermitUserEnvironment no/' /etc/ssh/sshd_config
RUN sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN echo "AuthorizedKeysCommand /usr/local/bin/get_pubkey.sh" >> /etc/ssh/sshd_config
RUN echo "AuthorizedKeysCommandUser nobody" >> /etc/ssh/sshd_config
RUN sed -i 's/cgroup_add_service$/echo "NexClipper" #cgroup_add_service#/g' /lib/rc/sh/openrc-run.sh
RUN rc-update add sshd
RUN mkdir /run/openrc && touch /run/openrc/softlevel
RUN rc-status
#RUN cat /etc/profile >> /root/.profile

WORKDIR	$WKDIR
CMD ["/bin/bash", "/entrypoint.sh"]

#ENTRYPOINT ["terraform"]
