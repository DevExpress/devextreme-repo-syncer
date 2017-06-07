FROM ubuntu:16.04
RUN apt-get update && apt-get install -y git mercurial rsync
ADD rootfs /
RUN [ -f /root/.hgrc ] || exit 1
CMD [ "./syncer.sh" ]
