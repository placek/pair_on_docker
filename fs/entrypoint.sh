#!/bin/ash

# exit when no keys available under .authorized_keys
if [ ! -f "/home/pair/workspace/.authorized_keys" ]; then
  >&2 echo "ERROR: no SSH keys in .authorized_keys"
  exit 1
fi

# set proper .ssh/authorized_keys
cat /home/pair/workspace/.authorized_keys | while read key; do
  echo "command=\"/usr/bin/tmux attach -t pair\" $key" >> /home/pair/.ssh/authorized_keys
done

# start tmux named session "pair" in deteached mode
su -c "tmux new -d -s pair -c /home/pair/workspace" pair

# start ssh daemon
exec /usr/sbin/sshd -Def /etc/ssh/sshd_config
