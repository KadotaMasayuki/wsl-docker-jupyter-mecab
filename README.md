# wsl-docker-jupyter-mecab

## 


## 参考文献

https://qiita.com/kojiue/items/f04443fcf1e0b4ddb31b



```
docker run --name jupyter-mecab-container --rm --detach --publish 8889:8888 --mount type=bind,src=$PWD,dst=/jupyter jupyter-mecab
```
