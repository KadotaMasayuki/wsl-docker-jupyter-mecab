#!/bin/bash

docker run --name jupyter-container --rm --detach --publish 8889:8888 --mount type=bind,src=$PWD,dst=/home/jupyter/src jupyter
