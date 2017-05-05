# `pair_on_docker`

This project is a sketch for a future tool to allow remote and secure pair programming.

### Assumptions

To start a pair programming session we need:

1. *Tools* - the programmers should have a bunch of tools that they are able to use during the pair programming session.
2. *Sandbox* - no matter who starts a session, the environment should contain ONLY the necessary content (tools, files, etc.). Programmers should be allowed to do EVERYTHING they need inside the environment without worry to break it. If the environment breaks it should be able to reset.
3. *The code* - of course programmers need to share the same code. After session the changes should be applied, so any changes made during the session should not be lost, although it should be possible to revert changes afterall.
4. *Connection* - pair programming should be available for anyone using internet connection. To start a session we need to use some tools that allows to work over the net.

### Implementation

To acomplish those goals we will use _git_ + _ssh_ + _docker_ + _tmux_.

Docker allows to build images cointaining the required set of tools. The images are easily managable and can be shared on need between programmers.

Every docker container provides a sandbox environment that is isolated from the host OS. The container can be launched and reset at will.

To share a code we will apply the _volume_ to the docker container. Volumes are accessable form container as well as from host. The volume will be our local repository so the changes will be tracked via _git_.

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

The current image of `reg01.binarapps.com/placzynskip/pair:latest` is available from B::A private docker registry [here](http://reg01.binarapps.com/repo/tags/placzynskip%252Fpair).

The image is founded on [`alpine:latest` image](https://hub.docker.com/_/alpine/) ([read more about Alpine linux](https://alpinelinux.org)) and contains only `openssh` and `tmux` packets.

To add more tools you need to write your own image basing on `reg01.binarapps.com/placzynskip/pair:latest`.

For example:

```docker
FROM reg01.binarapps.com/placzynskip/pair:latest
RUN \
  apk add --update vim git && \
  rm -rf /var/cache/apk/*
```

After that you need to build the image:

    $ docker build --tag pair .

Now we're ready to use the image.

###### Note

If you've built the base image by yourself you need to change

```docker
FROM reg01.binarapps.com/placzynskip/pair:latest
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

#### Lauching container

Now is time to lauch container:

    $ docker run --rm --detach --name pair_container --volume <project_path>:/home/pair/shared --publish 22:<port> pair

Explanation:
* `--rm` - we want to remove the container after we stop it.
* `--name pair_container` - to avoid using docker containers ids we name container.
* `--volume <project_path>:/home/pair/shared` - we share the `<project_path>` (the code) as `/home/pair/shared` in the container.
* `--publish 22:<port>` - publish port `22` (sshd) as `<port>` on localhost.
* `--detach` - we don't want the container to be attached to the tty.

#### Attach to the container

We use the `pair` user on the container. to attach to the container we simply use `ssh`:

    $ ssh -p <port> pair@localhost -t tmux a

If the `<port>` is different than `22` we need to add it to ssh options, i.e. `-p <port>`.

The pair-programming partner should be able to connect to the container with:

    $ ssh -p <port> pair@<your_ip> -t tmux a

After launching the container it includes a `tmux` session called `pair`. Every `ssh` connection automaticaly attaches to this session. The result is that you can follow every move of your partner (as well as he/she can).

The `-t tmux a` attaches to an existing tmux session.

Escaping from `tmux` session ends the `ssh` session too.

###### Note

If you are in B::A VPN you can simply use the local DNS:

    $ hostname
    mysupercomputer
    $ ssh pair@mysupercomputer.office.binarapps.com -t tmux a

If you are not able to use the VPN you can tunnel the SSH session via [ngrok](https://ngrok.com).

#### Stoping session

To end session we need to stop the container:

    $ docker stop pair_container

After that the pair-programming partner has no access to the code.
