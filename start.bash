#!/bin/bash

docker run --name jupyter-mecab-container --rm --detach --publish 8889:8888 --mount type=bind,src=$PWD,dst=/jupyter jupyter-mecab
