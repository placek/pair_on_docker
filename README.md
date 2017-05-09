# `pair_on_docker`

This project is a sketch for a future tool to allow remote and secure pair programming.

### Assumptions

To start a pair programming session we need:

1. *Tools* - the programmers should have a bunch of tools that they are able to use during the pair programming session.
2. *Sandbox* - no matter who starts a session, the environment should contain ONLY the necessary content (tools, files, etc.). Programmers should be allowed to do EVERYTHING they need inside the environment without worry to break it. If the environment breaks it should be able to reset. The environment should be isolated from a host environment and not affecting it.
3. *The code* - of course programmers need to share the same code. After session the changes should be applied, so any changes made during the session should not be lost. Although it should be possible to revert changes afterall.
4. *Connection* - pair programming should be available for anyone using internet connection. To start a session we need to use some tools that allows to work over the net.

### Implementation

To acomplish those goals we will use _git_ + _ssh_ + _docker_ + _tmux_.

Docker allows to build images cointaining the required set of tools. The images are easily managable and can be shared on need between programmers.

Every docker container provides a sandbox environment that is isolated from the host OS. The container can be launched and reset at will.

To share the code we will apply the _volume_ to the docker container. Volumes are accessable form container as well as from host. The volume will be our local repository so the changes will be tracked via _git_.

To access the sandbox we will use an _sshd_ service inside the container. To follow changes made by other programmers we will use _tmux_ sessions.

### Getting started

#### Install docker

To install docker simply follow instructions on [docker site](https://store.docker.com/editions/community/docker-ce-desktop-mac?tab=description).

#### Building the image

If for some reason you need/want to build the base image by yourself follow those instructions:

    $ git clone git@gitlab.binarapps.com:placek/pair_on_docker.git
    $ cd pair_on_docker
    $ docker build --tag pair_base .

#### Adjusting the image

The current image of `reg01.binarapps.com/placek/pair_on_docker:latest` is available from B::A private docker registry [here](http://reg01.binarapps.com/repo/tags/placek%252Fpair_on_docker).

The image is founded on [`alpine:latest`](https://hub.docker.com/_/alpine/) image ([more about Alpine linux](https://alpinelinux.org)) and contains only `openssh`, `curl` and `tmux` packets.

To add more tools you need to write your own image basing on `reg01.binarapps.com/placek/pair_on_docker:latest`.

For example:

```docker
FROM reg01.binarapps.com/placek/pair_on_docker:latest
RUN apk add --update --no-cache vim git
```

After that you need to build the image:

    $ docker build --tag pair .

Now we're ready to use the image.

###### Note (base image build locally)

If you've built the base image by yourself you need to change

```docker
FROM reg01.binarapps.com/placek/pair_on_docker:latest
```

to
```docker
FROM pair_base
```

### Pair programming session

#### Create a new branch in repo

Before we start session we need to set up the repository.

    $ cd <project_path>
    $ git checkout -B pair/with_placek

This point is optional, but it will keep the main branches clean and every change made during the session will be able to revert, add seperately or manages someway different at will. 

#### Lauching container

Now is time to lauch container:

    $ docker run --rm --detach --name pair_container --volume <project_path>:/home/pair/workspace --publish 22:<port> pair placzynskip guderskia

Or shorter:

    $ docker run --rm -d -n pair_container -v <project_path>:/home/pair/workspace -p 22:<port> pair placzynskip guderskia

Explanation:
 * `placzynskip guderskia` - the _LDAP_ logins are passed as arguments. Every login is being fetched from [keys.binarapps.com](keys.binarapps.com). We can pass more than two logins to provide multi-user session. If there is no argument passed, then docker container will not be launched and entrypoint script returns error code `1`. The same happens when any login from the arguments list has not been found on [keys.binarapps.com](keys.binarapps.com), but the errorcode then is `2`.
 * `--rm` - we want to remove the container after we stop it.
 * `--name pair_container` - to avoid using docker containers ids we name container.
 * `--volume <project_path>:/home/pair/workspace` - we share the `<project_path>` (the code) as `/home/pair/workspace` in the container.
 * `--publish 22:<port>` - publish port `22` (sshd daemon on docker container) as `<port>` on localhost.
 * `--detach` - we don't want the container to be attached to the tty. Instead it will show the id of the launched container. When we disable this option the container will write sshd logs to stdout.

#### Attach to the container

We use the `pair` user on the container. To attach to the container we simply use `ssh`:

    $ ssh -p <port> pair@localhost

If the `<port>` is different than `22` we need to add it to ssh options, i.e. `-p <port>`.

The pair-programming partner should be able to connect to the container with:

    $ ssh -p <port> pair@<your_ip>

After launching the container includes a `tmux` session called `pair`. Every `ssh` connection automaticaly attaches to this session. The result is that you can follow every move of your partner (as well as he/she can).

Escaping from `tmux` session ends the `ssh` session too.

###### Note (VPS host resolving)

If you are within B::A office network (or connected to the VPN) you can simply use the office DNS:

    $ hostname
    mysupercomputer
    $ ssh -p <port> pair@mysupercomputer.office.binarapps.com

###### Note (using external tunneling)

If you are not able to use the VPN you can tunnel the SSH session via [ngrok](https://ngrok.com).

###### Note (known hosts problem)

Since docker containers based on the `reg01.binarapps.com/placek/pair_on_docker:latest` may have different host keys (generated with `ssh-keygen` during building the image) there can appear the problem with caching those keys on every client machine.

By default hosts keys are being kept in `~/.ssh/known_hosts` and they are being appended to this file on very first connenction to host.

After the pair programming session will be launched on docker container every client will add it's host key to `known_hosts`. But later when container bases on other image the host key will differ and `ssh` will cowardly disconnect throwing a warning. We can avoid it by removing the kept key from `~/.ssh/known_hosts`.

On the other hand we can just launch `ssh` in "non-checking-known-host mode", using:

    $ ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p <port> pair@<your_ip>

#### Stoping session

To end session we need to stop the container:

    $ docker stop pair_container

After that the pair-programming partner has no access to the code.

### Read more

1. [`tmux` cheat-sheet](https://meerkat.binarapps.com/kd/guides/tmux-cheatsheet)
2. [`open_vpn` configuration & usage](https://meerkat.binarapps.com/kd/guides/openvpn)
3. [`ngrok` usage](https://ngrok.com/docs#getting-started)
4. _article_ [Remote Pair Programming Made Easy with SSH and tmux](http://hamvocke.com/blog/remote-pair-programming-with-tmux/)
