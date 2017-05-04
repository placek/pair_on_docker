FROM alpine:latest
MAINTAINER Paweł Placzyński <placzynski.pawel@gmail.com>

EXPOSE 22

ADD fs/sshd_config /etc/ssh/sshd_config
ADD fs/tmux_config /home/pair/.tmux.conf

RUN \
  apk add --update openssh tmux && \
  ssh-keygen -A && \
  adduser -D -s /bin/ash pair && \
  chown -R pair:pair /home/pair && \
  echo 'pair:' | chpasswd && \
  rm -rf /var/cache/apk/*

CMD \
  su -c 'tmux new -d -s pair -c /home/pair' pair && \
  exec /usr/sbin/sshd -Def /etc/ssh/sshd_config
