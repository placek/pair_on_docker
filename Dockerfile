FROM alpine:latest
MAINTAINER Paweł Placzyński <placzynski.pawel@gmail.com>

EXPOSE 22
ENTRYPOINT ["/bin/entrypoint"]

ADD fs/sshd_config /etc/ssh/sshd_config
ADD fs/tmux_config /home/pair/.tmux.conf
ADD fs/entrypoint.sh /bin/entrypoint

RUN \
  apk add --update openssh tmux curl && \
  ssh-keygen -A && \
  adduser -D -s /bin/ash pair && \
  mkdir /home/pair/.ssh && touch /home/pair/.ssh/authorized_keys && \
  chown -R pair:pair /home/pair && \
  echo "pair:$(date +%s)" | chpasswd && \
  rm -rf /var/cache/apk/*
