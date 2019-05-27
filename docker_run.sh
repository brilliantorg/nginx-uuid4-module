#!/usr/bin/env bash

docker build -t nginx-uuid .
if [ $? -eq 0 ]; then
    docker run --rm -it -v $(pwd):/srv/server nginx-uuid
fi
