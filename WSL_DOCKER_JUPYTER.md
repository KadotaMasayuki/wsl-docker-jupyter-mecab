# wsl-docker-jupyter

Windows11 > WSL2 > Ubuntu > Docker > Jupyterlab という構成で`jupyterlab`環境を作成。
Windows上のブラウザから http//localhost:8889/ へアクセスすると`docker->jupyterlab:8888`へ接続しJupyterlabを利用できる。
python3.11とmecabとwordcloudを使えるようにしてある。


# 参考文献(docker, mecab, jupyter)

https://qiita.com/kojiue/items/f04443fcf1e0b4ddb31b


# 確認環境

Windows11 Home 22H2 22621.2715

WSL uname -a → Linux 5.15.133.1-microsoft-standard-WSL2 #1 SMP Thu Oct 5 21:02:42 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux

Docker version 24.0.7, build afdd53b

Docker内のpythonバージョン 3.11

** proxy環境下で構築するときは、[proxy環境のwindowsで、wsl2にdockerを入れる！](https://github.com/KadotaMasayuki/wsl-docker/blob/main/README.md)を参照。 **

ディレクトリ構成

```
~/
   jupyter/
      docker/
         Dockerfile
         create.bash
         start.bash
      notebook/
         作ったノートブック等
          ;
```


# ディレクトリを準備する

:::note info
wslやlinuxをリセットするなどで、作ったノートブックが消えることを避けるため、データ類はwindows上で管理する
:::

windows上の任意のディレクトリに、`docker`ディレクトリと、`notebook`ディレクトリを作る。
`docker`ディレクトリ内に、`Dockerfile`と`create.bash`と`start.bash`を格納しておく。

たとえば、ユーザー`a user`の`マイドキュメント`の`wsl_test`の`jupyter_test`ディレクトリを以下のように準備する。

```
windows/c/Users/a user/My Documents/wsl_test/jupyter_test/
    docker/
        Dockerfile
        create.bash
        start.bash
    notebook/
```

つづいて、wsl上にjupyterディレクトリを作る。
wslからは、windowsのディレクトリは、`/mnt/C/Users/a user/My Documents/wsl_test/jupyter_test`というパスで辿れるので、このパスをwslのホームディレクトリにシンボリックリンクする。

```
wsl $ cd ~/
wsl $ ln -s /mnt/C/Users/a user/My Documents/wsl_test/jupyter_test jupyter
wsl $ ls -lX
lrwxrwxrwx 1 yourname   jupyter -> '/mnt/C/Users/a user/My Documents/wsl_test/jupyter_test'
wsl $ ls jupyter
docker/  notebook/
wsl $
```


# Dockerイメージ生成

wsl上で、Dockerfileと同じディレクトリで以下を実行する。

```
wsl $ ./create.bash
```

または

```
wsl $ docker build -t jupyter .
```

2.01GB。けっこう大きい。
`FROM ubunth:22.04`として少しずつ作ってゆくと900MB程度で収まるかもしれないが、JupyterlabでPythonをゴリゴリ書きたいのでPythonイメージを基準につくってみた。

```
docker image list
REPOSITORY             TAG       IMAGE ID       CREATED          SIZE
jupyter          latest    xxxxxxxx       59 minutes ago   2.01GB
```


# Dockerfile解説


## python + jupyterlabを想定しているため、python環境をベースとして組み立てる。

```
# base image
FROM python:3.11
```


## 一部タイムゾーンの設定が必要なパッケージがあることがある（このDockerfile内では不要かも）ので設定しておく。

```
# correct time-zone
ENV TZ=Asia/Tokyo
```


## mecabコマンドと辞書をインストール

```
# apt install
RUN apt update && \
  apt -y install mecab libmecab-dev mecab-ipadic-utf8

# apt clear
RUN apt autoremove -y
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


### なぜ、Dockerfile内ではapt install と apt update を同じ行に書くのか

```
# apt install
RUN apt update && \
  apt -y install mecab libmecab-dev mecab-ipadic-utf8
```

`docker build`コマンドはDockerfile内の変更があった行を処理し、変更が無かった行の操作はキャッシュを使用するらしい( https://docs.docker.jp/develop/develop-images/dockerfile_best-practices.html#apt-get )。
そのため、`apt install`の行が更新されても`apt update`の行が更新されない限りは`apt update`されないまま古いパッケージが`apt install`されてしまう。
なので、つなげて書く必要がある。


RUN apt update && apt install の動作例として、

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


## python3の必要パッケージをインストールする

```
# pip install
RUN pip3 install --upgrade pip
RUN pip3 install jupyterlab
RUN pip3 install pandas
RUN pip3 install mecab-python3
RUN pip3 install wordcloud
```


## mecabコマンドとmecab-pythonとで必要ファイルのパスを合わせる

mecabコマンドの`mecabrc`のパスが`/etc/mecabrc`だが、`mecab-python3`は`/usr/local/etc/mecabrc`にあってほしいと望んているため、シンボリックリンクを張る。

```
# add link /etc/mecabrc to mecab-python3 target as /usr/local/etc/mecabrc
RUN ln -s /etc/mecabrc /usr/local/etc/mecabrc
```


### mecabrcへのシンボリックリンクが必要な理由

シンボリックリンクを張らないDockerfileで作ったイメージ内でpythonで書いてみると次のようにエラーが出る。

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

findしてみると、確かに`/usr/local/etc/mecabrc`は無い。

```
docker $ find / -name mecabrc -print
/etc/mecabrc
```

なので、シンボリックリンクを張る。

```
docker $ sudo ln -s /etc/mecabrc /usr/local/etc/mecabrc
docker $ ls -al /usr/local/etc
lrwxrwxrwx  1 root root   12 Nov 26 08:51 mecabrc -> /etc/mecabrc
```

もういちどpythonでプログラムを書いてみる。

```
docker $ python3
Python 3.11.2 (main, Mar 13 2023, 12:18:29) [GCC 12.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import MeCab
>>> wakati = MeCab.Tagger("-Owakati")
>>> text = "すもももももももものうち"
>>> result = wakati.parse(text)
>>> print(result)
すもも も もも も もも の うち

>>>
```

これで動くことが確認できたので、Dockerfileにも同じ処理を入れてある。


## 日本語フォントを入れる

```
# add japanese font
RUN apt install curl unzip
RUN curl -L -o HackGen_v2.9.0.zip https://github.com/yuru7/HackGen/releases/download/v2.9.0/HackGen_v2.9.0.zip
RUN unzip HackGen_v2.9.0.zip
RUN mv HackGen_v2.9.0 /usr/local/share/fonts/HackGen
RUN rm HackGen_v2.9.0.zip
```

curlでのダウンロードが失敗する場合、proxy環境下であれば、まずは、[proxy環境のwindowsで、wsl2にdockerを入れる！](https://github.com/KadotaMasayuki/wsl-docker/blob/main/README.md)をやってみる。それでもダメ、またはproxy環境ではないのに失敗する、という場合は、curlコマンドに`-k`オプションを付けてみると認証関係のエラーを回避できるかもしれない。


フォントを`/user/local/share/fonts/`ディレクトリに入れることで、jupyter lab上で

```
import matplotlib.font_manager as fm
fm.findSystemFonts()
```

とすると、以下のようにフォント一覧が得られる。


```
 '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'
 '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGen-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGen-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGenConsole-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGenConsole-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35Console-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35Console-Bold.ttf',
```

このリストの中から、フルパスで`/usr/local/share/fonts/HackGen/HackGen-Regular.ttf`を指定するなどして、jupyterlabで使える。
ディレクトリがなく、フォント名だけが表示されることがあるので、そのときは表示されたままのフォント名を指定すれば良い。


## jupyterlabを起動する

```
# run jupyter-lab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--LabApp.token=''", "--port=8888"]
```

待ち受けportは8888。デフォルトなので書く必要はないが、書けば探しやすい。

Dockerfileここまで。


# コンテナ生成

```
wsl $ ./start.bash
```

または

```
wsl $ docker run --name jupyter-container --rm --detach --publish 8889:8888 --mount type=bind,src=${HOME}/jupyter/notebook,dst=/jupyter --workdir /jupyter jupyter
```

でコンテナ生成。

** --name docker ** ps で見えるコンテナ名を`jupyter-container`にする

** --rm ** コンテナ終了したら自動で削除する。

** --detach ** バックグラウンドで起動。

** --publish ** コンテナ外(wsl)のport8889と、コンテナ内のport8888とを接続する。

** --mount ** コンテナ外(wsl)のホームディレクトリ中のjupyter/srcディレクトリ`${HOME}/jupyter/src`を、コンテナ内の`/jupyter`ディレクトリとしてマウントする。

** --workdir ** コンテナ内の`/jupyter`ディレクトリで作業する

** jupyter ** イメージ`jupyter`からコンテナを起動する


# Windowsからdocker内のJupyterlabへ接続

Windowsのブラウザから、( http://localhost:8889/ )へ接続すると、jupyterlabの画面になる。

** wslのport8889と、windowsのportXXXXを対応付けなきゃ！　と思っていたが、不要のようだ。 **


# 保存したファイルの所在

jupyterlab上の`/jupyter`ディレクトリにノートブックを保存すると、`wsl`上の`~/jupyter/notebook`ディレクトリ( = windows上のディレクトリ) にノートブックが出来上がる。

:::note info
windowsから`wsl`内のファイルを見たい場合は、windowsから`\\wsl$`でアクセスできる。

wslからwindowsのファイルを見たい場合は、`/mnt/C/.....`でアクセスできる。
:::


# Jupyterlabで日本語フォントを使う

日本語フォントを導入する項でも書いたとおり、JupyterlabでPythonのソースコードを作成し、次のように入力すると、使用できるフォントのリストが得られる。

```
import matplotlib.font_manager as fm
fm.findSystemFonts()

 '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'
 '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGen-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGen-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGenConsole-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGenConsole-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35-Bold.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35Console-Regular.ttf',
 '/usr/local/share/fonts/HackGen/HackGen35Console-Bold.ttf',
```

この中で、`HackGen/HackGen****.ttf`というものが日本語フォント。

以下のように入力すると、ひらがなの発生頻度に応じて文字サイズの違うひらがなが表示される。
また、表示されているものと同じ画像が、ソースコードと同じディレクトリ内に`wordcloud.png`という名前で作成される。

```
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
font_path = "/usr/local/share/fonts/HackGen/HackGen-Regular.ttf"
wc = WordCloud(font_path=font_path)
wc.generate("あ い う え お あ あ あ い え")
plt.imshow(wc)
wc.to_file("wordcloud.png")
```

以上
