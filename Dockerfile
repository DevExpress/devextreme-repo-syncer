FROM alpine:3.11
RUN apk add --no-cache bash findutils git mercurial rsync
ADD rootfs /
RUN [ -f /root/.hgrc ] || exit 1
CMD [ "./syncer.sh" ]
