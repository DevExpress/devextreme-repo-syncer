FROM alpine:3.12
RUN apk add --no-cache bash findutils git mercurial rsync
RUN git config --global gc.autodetach false
RUN apk add --no-cache --upgrade grep
RUN apk add --no-cache openssh
ADD rootfs /
RUN [ -f /root/.hgrc ] || exit 1
CMD [ "./syncer.sh" ]
