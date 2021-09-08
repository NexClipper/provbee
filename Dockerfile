FROM alpine:latest 
#alpine:3.12.3 - 2020.12.31
LABEL maintainer="NexCloud Peter <peter@nexclipper.io>"

RUN apk add --no-cache --update git bash unzip curl openssh-server openssh-client openssl openrc jq
#RUN apk add --no-cache --update gcc musl-dev make openssh-keygen
#RUN apk add --no-cache --update curl unzip openssh-server openrc jq bash
ENV TF_DEV=true
ENV TF_RELEASE=1

## WorkDIR & tmpDIR make
ENV WKDIR=/data
ENV PATH /usr/local/bin:$PATH
WORKDIR	$WKDIR

COPY entrypoint.sh /entrypoint.sh
COPY ./scripts /tmp/scripts
RUN sh -x /tmp/scripts/init.sh


RUN rc-update add sshd; mkdir /run/openrc && touch /run/openrc/softlevel; rc-status

CMD ["/bin/bash", "/entrypoint.sh"]
#CMD ["/bin/sh"]
#ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["terraform"]
