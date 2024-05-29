FROM alpine:3.12
RUN apk add --no-cache bash findutils git git-lfs mercurial rsync grep openssh
RUN git config --global gc.autodetach false \
 && git config --global gc.auto 0
ADD rootfs /
RUN [ -f /root/.hgrc ] || exit 1
CMD [ "./syncer.sh" ]
