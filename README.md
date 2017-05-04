# pair on docker


## build

    docker build -t pair .

## use

    docker run --rm --name pair_container --volume <shared_directory_path>:/home/pair/shared --publish 22:22 pair


    ssh pair@localhost
