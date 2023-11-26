# wsl-docker-jupyter-mecab

Windows11 > WSL2 > Ubuntu > Docker という構成で`jupyterlab`を作成。
Windows上のブラウザから http//localhost:8889/ へアクセスすると`jupyterlab`を利用できる。


## 参考文献

https://qiita.com/kojiue/items/f04443fcf1e0b4ddb31b


## 確認環境

Windows11 > WSL2 > Ubuntu > Docker

Windows11 Home 22H2 22621.2715

uname -a → Linux 5.15.133.1-microsoft-standard-WSL2 #1 SMP Thu Oct 5 21:02:42 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux

Docker version 24.0.7, build afdd53b

Docker内のpython 3.11


## Dockerイメージ生成

Dockerfileと同じディレクトリで以下を実行する。

```
wsl $ ./createcontainer.bash
```

または

```
wsl $ docker build -t jupyter-mecab .
```


## Dockerfile解説

### python + jupyterlabを想定しているため、python環境をベースとして組み立てる。

```
FROM python:3.11
```

### 一部タイムゾーンの設定が必要なパッケージがあることがある（このDockerfile内では不要かも）ので設定しておく。

```
ENV TZ=Asia/Tokyo
```

### Dockerfile内ではapt install は apt update と同じ行に書く

```
RUN apt update && apt -y install .....
```

Dockerfileは行単位で変更の有無を確認されるらしく( https://scrapbox.io/ima1zumi/RUN_apt-get_update_%E3%81%A8_apt-get_install_%E3%81%AF%E3%80%81%E5%90%8C%E4%B8%80%E3%81%AE_RUN_%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89%E5%86%85%E3%81%AB%E3%81%A6%E5%90%8C%E6%99%82%E5%AE%9F%E8%A1%8C%E3%81%99%E3%82%8B )、`apt install`の行が更新されても`apt update`の行が更新されない限りは`apt update`されないまま`apt install`されてしまう。

例

```
RUN apt update
RUN apt install a
RUN apt install b
```

のあと、

```
RUN apt update
RUN apt install c
RUN apt install b
```

とすると、`RUN apt install c`行だけが更新されているため、`apt update`をせずに`apt install c`してしまう。
なので、`RUN apt update && apt install c`と書くことで毎行`apt update`されるようになって、希望した最新のパッケージがインストールされる。

### mecabコマンドと辞書をインストール

```
RUN apt install mecab libmecab-dev mecab-ipadic-utf8
```

これによりmecabコマンドを使用できる。コマンド入力してEnter後、文章を入力してEnterすると構文解析される。

```
wsl $ mecab
すもももももももものうち
すもも  名詞,一般,*,*,*,*,すもも,スモモ,スモモ
も      助詞,係助詞,*,*,*,*,も,モ,モ
もも    名詞,一般,*,*,*,*,もも,モモ,モモ
も      助詞,係助詞,*,*,*,*,も,モ,モ
もも    名詞,一般,*,*,*,*,もも,モモ,モモ
の      助詞,連体化,*,*,*,*,の,ノ,ノ
うち    名詞,非自立,副詞可能,*,*,*,うち,ウチ,ウチ
EOS
(Ctrl-cで終了)
```

### mecabコマンドとmecab-pythonとで必要ファイルのパスを合わせる

```
RUN ln -s /etc/mecabrc /usr/local/etc/mecabrc
```

mecabコマンドの`mecabrc`のパスが`/etc/mecabrc`だが、`mecab-python3`は`/usr/local/etc/mecabrc`にあってほしいと望んているため、シンボリックリンクを張る。

シンボリックリンクを張らずにpythonで書いてみると次のようにエラーが出る。

```
docker $ python3
Python 3.11.2 (main, Mar 13 2023, 12:18:29) [GCC 12.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import MeCab
>>> wakati = MeCab.Tagger("-Owakati")
Traceback (most recent call last):
  File "/home/xxxx/jupyterlab/venv/lib/python3.11/site-packages/MeCab/__init__.py", line 137, in __init__
    super(Tagger, self).__init__(args)
RuntimeError

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/home/xxxx/jupyterlab/venv/lib/python3.11/site-packages/MeCab/__init__.py", line 139, in __init__
    raise RuntimeError(error_info(rawargs)) from ee
RuntimeError:
----------------------------------------------------------

Failed initializing MeCab. Please see the README for possible solutions:

    https://github.com/SamuraiT/mecab-python3#common-issues

If you are still having trouble, please file an issue here, and include the
ERROR DETAILS below:

    https://github.com/SamuraiT/mecab-python3/issues

issueを英語で書く必要はありません。

------------------- ERROR DETAILS ------------------------
arguments: -Owakati
default dictionary path: None
[ifs] no such file or directory: /usr/local/etc/mecabrc
----------------------------------------------------------

>>> exit()
```

### jupyterlabを起動する

```
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--LabApp.token=''", "--port=8888"]
```

待ち受けportは8888。デフォルトなので書く必要はないが、書けば探しやすい。


## コンテナ生成

```
wsl $ ./start.bash
```

または

```
wsl $ docker run --name jupyter-mecab-container --rm --detach --publish 8889:8888 --mount type=bind,src=$PWD,dst=/jupyter jupyter-mecab
```

でコンテナ生成して、バックグラウンドで起動。

コンテナ内のport8888と、コンテナ外のport8889を接続する。

コンテナ内の`/jupyter`ディレクトリと、コンテナ外の現在のディレクトリを紐づける。

コンテナ終了したら自動で削除する。


## Windowsからlupyterlabへ

Windowsのブラウザから、( http://localhost:8889/ )へ接続すると、jupyterlabの画面になる。
`/jupyter`ディレクトリで、`wsl`とファイルのやり取りができる。

