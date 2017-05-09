#!/bin/ash

# when no USERS variable set exit with errcode 1
if [ -z "$USERS" ]
then
   >&2 echo "ERROR: You need to provide LDAP logins in USERS variable!"
   exit 1
fi

for user in `echo $USERS | tr "," "\n"`
do
  # fetch pubkeys by LDAP user login
  echo "Fetching key for $user..."
  KEY=$(su -c "curl https://keys.binarapps.com/$user 2>/dev/null")

  # on fetch fail exit with errcode 2
  if [ "$KEY" = "not found" ]
  then
   >&2 echo "ERROR: Failed fetching key for $user!"
   exit 2
  fi

  # append key to authorized_keys
  su -c "echo 'command=\"/usr/bin/tmux new -s $user -t pair\" $KEY' >> /home/pair/.ssh/authorized_keys" pair
done

# start tmux named session "pair" in deteached mode
su -c "tmux new -d -s pair -c /home/pair" pair

# start ssh daemon
exec /usr/sbin/sshd -Def /etc/ssh/sshd_config
