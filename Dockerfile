FROM alpine:latest

RUN apk add --update --no-cache openssh tmux vim && \
    ssh-keygen -A && \
    adduser -D -s /bin/ash pair && \
    echo "pair:$(date +%s)" | chpasswd && \
    mkdir /home/pair/.ssh && touch /home/pair/.ssh/authorized_keys && \
    chown -R pair:pair /home/pair

EXPOSE 22
ENTRYPOINT /bin/entrypoint

ADD fs/sshd_config /etc/ssh/sshd_config
ADD fs/entrypoint.sh /bin/entrypoint
