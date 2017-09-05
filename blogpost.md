# Pair programming with Docker, SSH and TMUX
###### _aka. distributed pair programming_

Pair programming is a well known practice in agile development. The principles here are simple: sit next to your colegue, let them write the code (_the driver_) while you will be planing/reviewing/instructing (_the navigator_).
This practice separates the thinking processes of implementation and strategy from each other. It helps to focus on a particular aspect at the moment. Programmers all over the world are pairing to gain experiance, increase productivity, solve complex problems, debug, refactor, etc.

As long as pair programming session participants are phisicaly present to each other (for instance: they are in the same office) the session itself can be performed painlessly without encountering any technical difficulties. However, as the distance between participants grows, the contact between them is getting worse. The critical point is when programmers taking part in session are in different rooms. That's where we need to implement some distributed solution!

## What we realy need?

The truth is while being remote the contact can be harder to obtain. There are several ways for overcame that problem: for example we can use some known solution to do get in touch with each other, like phone call, VoIP, mumble, Skype, Hangouts, etc. However, is the verbal contact the only resource we lack in such situation?

Lets think about it! To set up the pair programming session we actualy need four other factors to be fullfiled:

### The code

First of all the participants need to share the same code. The code is the actual material we are working on.

Moreover, after such session the changes have to be accessable for the participants - any changes made during the session should not be lost. On the other hand, it would be nice to have a possibility of reverting changes afterall.

It is important that programmers are working on the actual version of the code. The changes made by one side should be visible/editable for the other side. Each participant should be able to follow the changes the others make in real time.

### The toolbox

The programmers should have a bunch of tools that they are able to use during the pair programming session.

Again, "the toolbox" should contain the same set of tools for each side (same implementations, versions, architecture, etc.) - if not, the results of testing such project will differ or eventualy not work at all.

### The sandbox

There is always someone, who starts and sets the session up. No matter who does this, the environment have to contain only the necessary content (tools, files, etc.). Participants should be allowed to do everything they need inside the environment without worry to break it. If the environment somehow breaks it should be easily reversable.

The environment should be isolated from a host environment and not affecting it. Otherwise one of the sides can be vulnerable during such session. The pair programing session is an experiment time - programmers will want to exploit it, so the environment should act like a mad scientists lab hidden in the bunker in the middle of a desert.

### The medium

Last, but not least: Pair programming session should be available for every person we want to start the participation with. To acomplish that we need to use some common tools that allows to work over the internet. Our partners should be able to easily join us without not taking any hard effort.

Also, the medium has to be safe - our resources should be protected from any exploits or attacks.

## How will we do that?

### Technologies

To acomplish those goals we will use `docker`, `ssh` and `tmux`. Additionaly we can use `git`.

#### Docker

On [Docker's site](https://www.docker.com/what-docker) we read:

> Docker is the world’s leading software container platform. Developers use Docker to eliminate "works on my machine" problems when collaborating on code with co-workers. Operators use Docker to run and manage apps side-by-side in isolated containers to get better compute density. Enterprises use Docker to build agile software delivery pipelines to ship new features faster, more securely and with confidence for both Linux, Windows Server, and Linux-on-mainframe apps.

Docker is one of the known ways to perform virtualization. We can easily launch an isolated environment to use specific software we need.

##### Images

Docker bases on, so called, _images_. An image is a filesystem containing all the data i.e. libraries, binary files, media, etc. We can think of image as of the disk partition contiainting the OS files, configuration, software, software dependencies and anything we can imagine to run this software on the dedicated OS.

There are plenty images on [Docker Hub](https://hub.docker.com) that we can use after downloading. We can also [build our own images](https://www.howtoforge.com/tutorial/how-to-create-docker-images-with-dockerfile/) and that is what we are going to do here.

##### Containers

Docker images can be launched as a separate "guest OS". Every instance of such "launched image" is called the _container_. There can be a lot of containers on host OS using just one image. Container does not modify host OS filesystem - in fact it does not modify the image too. Recalling our comparation of image to a hard drive partition, we can now say that image has read-only access and all the oparations the container is performing are being done in ramdisk.

##### Volumes

Every container can use some pre-configured directories "shared" by host OS. Those direstories are called _volumes_. Volume is mounted in guest OS, but first we need to tell docker where we want to mount such volume and what is the path of the "shared directory" on our host OS.

Once the container stops running the data in the volume remains. Several containers can use the same volume.

##### Networking

Every docker container can communicate with an outer world using TCP interface. SAme as with volumes we can _expose_ the TCP port. Exposing the port means to grant access to that port from the host OS - by default this access is denied.

##### And more...

Docker has many "magic" features one can use. Once you get familliar with the basics of docker you can [learn more about it](https://docs.docker.com).

#### SSH

Secure Shell (SSH) is a cryptographic network protocol for operating network services securely over an unsecured network. The best known example application is for remote login to computer systems by users.

SSH provides a secure channel over an unsecured network in a client-server architecture, connecting an SSH client application with an SSH server. Common applications include remote command-line login and remote command execution, but any network service can be secured with SSH.

For our pair programming purposes we will use it to provide the secure connection between participants. The connection will prevent participants from exploits and leaks.

#### TMUX

[TMUX](https://github.com/tmux/tmux) is a "terminal multiplexer", it enables a number of terminals (or windows) to be accessed and controlled from a single terminal. Those "windows" can be accessed also by other users. It means whe can open our text editor, list log files, check the stdout of out application, etc. and swiftly swich between those windows - even open them side by side in one terminal! And that can be done by our friends too! It's like having tabs and windows in GUI and our colegues can manipulate them too. We can customize it, we can deteach them and reattach later. It is one of the best tools to use with pair programming.

### Workflow

The less effort the participants need to take to start the pair programming session - the better!

The main idea is to prepare universal tool that is simple to launch for an initiator of the session and easy to access by others involved.

As long as we follow that assumptions we will be able to make a docker image that provides us the toolbox we need and is easily accessable. Everytime we want to start a pair programming session we will use that image to run a container that has one volume attached - our code directory. The container will provide an `sshd` service so - in the result - it will be accessable for participants.

In the end participants will need no more than an SSH client to start pair programming with us.

### Implementation

The plan is:
1. We will build a docker image with all required tools, libraries and dependencies we need to perform a pair programming session.
2. We will launch the image.
3. We will apply a voulume to the running container. The volume will be our projects's directory.
4. We will expose SSH port so anyone will be able to connect to our container.

#### The image

Firstly, we need to choose the OS we want our environment to run on. We literally can use anything that [hub.docker.com](hub.docker.com) provides us. Remember, the OS should fit our needs.

For some realy well-equipped environment we can use [centos](https://hub.docker.com/_/centos/), [ubuntu](https://hub.docker.com/_/ubuntu/), [debian](https://hub.docker.com/_/debian/), etc, but for the case of this presentation we would rather choose something much lighter and smaller - afterall we want to share the image, customize and build it quickly on need. For that let's take [alpine](https://hub.docker.com/_/alpine/) - it weights about 4MB, it has a built-in manager `apt` with
a lot of packages delivered and of course it's a linux.

Now we will write our `Dockerfile`. We will start with specifying the base image:

    FROM alpine:latest

Now we will install required tools. The absolute minimum for our purposes are SSH server and tmux:

    RUN apk add --update --no-cache openssh tmux

#### The SSH server

Now we will configure SSH to allow pair-programers to connect with the container. We will add this to `Dockerfile`.

Firstly we want to generate SSH keys for the server:

    RUN ssh-keygen -A

Now we need to setup the target user. I've called it `pair`:

    RUN adduser -D -s /bin/ash pair
    RUN echo "pair:$(date +%s)" | chpasswd
    RUN mkdir /home/pair/.ssh && touch /home/pair/.ssh/authorized_keys
    RUN chown -R pair:pair /home/pair

Instead of `$(date +%s)` we can provide some secret password here, but I recommend using `.ssh/authorized_keys` instead - it is safer not to save any password in plain text anywhere!

To finish configuration for SSH we will provide an `sshd_config`:

    ADD sshd_config /etc/ssh/sshd_config

Where the content of `sshd_config` is:

    Protocol 2
    Port 22
    PubkeyAuthentication yes
    PasswordAuthentication no
    AllowTcpForwarding no
    X11Forwarding no
    AllowUsers pair
    PrintMotd no
    IgnoreUserKnownHosts yes
    PermitRootLogin no
    PermitEmptyPasswords no

The last thing to do is to expose the SSH `22` port in `Dockerfile`, so the outer world can connect to the container via this port:

    EXPOSE 22

#### The SSH keys

To provide connection with container we need to setup the SSH keys. We will get those from [GitHub API](https://developer.github.com/v3/users/keys/). At first we will add the `curl` tool to connect with the API, so we modify:

    RUN apk add --update --no-cache openssh tmux

to:

    RUN apk add --update --no-cache openssh tmux curl

The SSH keys will be indentified by GitHub login. To tell docker container which logins we are interested in we will type those logins as arguments for the `docker run` command. Do do that we need the script that will recognise those logins, download the key and add it to `.ssh/authorized_keys`:

    #!/bin/ash

    # when no arguments given exit with errcode 1
    if [ -z "$@" ]
    then
       >&2 echo "ERROR: You need to provide GitHub logins!"
       exit 1
    fi

    for user in $@
    do
      echo "Fetching key for $user..."
      # fetch pubkeys by GitHub user login
      RESPONSE=$(su -c "curl https://api.github.com/users/$user/keys 2>/dev/null")
      # get the key from JSON
      KEY=$(echo $RESPONSE | sed -n 's/"key": "\(.*\)"/\1/p' | head -n1)

      # append the key to authorized_keys
      su -c "echo '$KEY' >> /home/pair/.ssh/authorized_keys" pair
    done

    # start ssh daemon
    exec /usr/sbin/sshd -Def /etc/ssh/sshd_config

We will name the script an `entrypoint.sh` and add it to `Dockerfile`:

    ADD entrypoint.sh /bin/entrypoint

Now we can set `entrypoint.sh` as an entrypoint of the docker container:

    ENTRYPOINT ["/bin/entrypoint"]

#### TMUX session

TMUX provides some cool feature - sessions sharing. It means that people that use TMUX can work on the same session i.e. have the same TMUX windows/screens, see the same output/logs, know of every move the other person is doing, etc. That's what we expect from the toolset when we are doing the pair programming!

To enter such session we will add a line to our `entrypoint.sh`:

    su -c "tmux new -d -s pair -c /home/pair" pair

It means that we run a new named session called `pair` in the deteached mode with a current directory set to `/home/pair`.

To join such session a user needs to type `tmux new -s my_login -t pair`. To make it automaticaly we will enforce the `command` option in `.ssh/authorized_keys`, so in `entrypoint.sh` we will change:

      # append the key to authorized_keys
      su -c "echo '$KEY' >> /home/pair/.ssh/authorized_keys" pair

to:

      # append the key to authorized_keys
      su -c "echo 'command=\"/usr/bin/tmux new -s $user -t pair\" $KEY' >> /home/pair/.ssh/authorized_keys" pair

#### Final file system

We should end up with `Dockerfile` like:

    FROM alpine:latest

    EXPOSE 22
    ENTRYPOINT ["/bin/entrypoint"]

    ADD sshd_config /etc/ssh/sshd_config
    ADD entrypoint.sh /bin/entrypoint

    RUN apk add --update --no-cache openssh tmux curl
    RUN ssh-keygen -A
    RUN adduser -D -s /bin/ash pair
    RUN echo "pair:$(date +%s)" | chpasswd
    RUN mkdir /home/pair/.ssh && touch /home/pair/.ssh/authorized_keys
    RUN chown -R pair:pair /home/pair

the `sshd_config`:

    Protocol 2
    Port 22
    PubkeyAuthentication yes
    PasswordAuthentication no
    AllowTcpForwarding no
    X11Forwarding no
    AllowUsers pair
    PrintMotd no
    IgnoreUserKnownHosts yes
    PermitRootLogin no
    PermitEmptyPasswords no

and `entrypoint.sh`:

    #!/bin/ash

    # when no arguments given exit with errcode 1
    if [ -z "$@" ]
    then
       >&2 echo "ERROR: You need to provide GitHub logins!"
       exit 1
    fi

    for user in $@
    do
      echo "Fetching key for $user..."
      # fetch pubkeys by GitHub user login
      RESPONSE=$(su -c "curl https://api.github.com/users/$user/keys 2>/dev/null")
      # get the key from JSON
      KEY=$(echo $RESPONSE | sed -n 's/"key": "\(.*\)"/\1/p' | head -n1)

      # append the key to authorized_keys
      su -c "echo 'command=\"/usr/bin/tmux new -s $user -t pair\" $KEY' >> /home/pair/.ssh/authorized_keys" pair
    done

    # start ssh daemon
    exec /usr/sbin/sshd -Def /etc/ssh/sshd_config

#### Building image

Now we can finally build the docker image:

    $ docker build --tag pair_base .

## Usage

Now having the image with the environment set up we can use it!

### Create a new branch in repo

Before we start session we want to set up the repository. If we use the `git` tool we would like to create a separate branch:

    $ cd <project_path>
    $ git checkout -B pair/with_placek

This point is optional, but it will keep the main branches clean and every change made during the session will be able to revert, add seperately or manages someway different at will.

### Lauching container

Now is time to lauch container:

    $ docker run --rm --detach --name pair_container --volume <project_path>:/home/pair/workspace --publish 22:<port> pair placek przymusiala

Or shorter:

    $ docker run --rm -d -n pair_container -v <project_path>:/home/pair/workspace -p 22:<port> pair placek przymusiala

Explanation:
 * `placek przymusiala` - the _GitHub_ logins are passed as arguments. We can pass more than two logins to provide multi-user session. If there is no argument passed, then docker container will not be launched and entrypoint script returns error code `1`.
 * `--rm` - we want to remove the container after we stop it.
 * `--name pair_container` - to avoid using docker containers ids we name container.
 * `--volume <project_path>:/home/pair/workspace` - we share the `<project_path>` (the code) as `/home/pair/workspace` in the container.
 * `--publish 22:<port>` - publish port `22` (sshd daemon on docker container) as `<port>` on localhost.
 * `--detach` - we don't want the container to be attached to the tty. Instead it will show the id of the launched container. When we disable this option the container will write sshd logs to stdout.

### Attach to the container

We have already set up the `pair` user on the container. To attach to the container we simply use `ssh`:

    $ ssh pair@localhost

If the `<port>` is different than `22` we need to add it to ssh options, i.e. `-p <port>`.

The pair-programming partner should be able to connect to the container with:

    $ ssh pair@<our_ip>

After launching the container already includes a `tmux` session called `pair`. Every `ssh` connection automaticaly attaches to this session. The result is that you can follow every move of your partner (as well as they can).

Escaping from `tmux` session ends the `ssh` session too.

###### Note (VPS host resolving)

If you are within the office network (or if you are connected to the VPN) you can simply use the office DNS or local IPs. Otherwise you will be in need to use something like [`ngrok`](https://ngrok.com).

### Stoping session

To end session we need to stop the container:

    $ docker stop pair_container

After that the pair-programming partner has no access to the code.

## Epilogue

Docker provides some good basis to create an isolated environment. Using it as a pair-programming toolbox is just a one possibility. We can freely use some other virtualization method as well.

TMUX is a good option to follow the work of your colegues and share the experience during the session. It helps with the communication during the simultainous work on the code, file system and software.

SSH is here a good medium to provide connection with your team. It grants secure access to the environment and the code.
