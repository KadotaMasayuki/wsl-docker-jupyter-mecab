# wsl-docker-jupyter-mecab

Windows11 > WSL2 > Ubuntu > Docker という構成で`jupyterlab`を作成。
Windows上のブラウザから http//localhost:8889/ へアクセスすると`jupyterlab`を利用できる。
python3.11とmecabを使えるようにしてある。


# 参考文献(docker, mecab, jupyter)

https://qiita.com/kojiue/items/f04443fcf1e0b4ddb31b


# 確認環境

Windows > WSL2 > Ubuntu > Docker

Windows11 Home 22H2 22621.2715

uname -a → Linux 5.15.133.1-microsoft-standard-WSL2 #1 SMP Thu Oct 5 21:02:42 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux

Docker version 24.0.7, build afdd53b

Docker内のpythonバージョン 3.11


# Dockerイメージ生成

Dockerfileと同じディレクトリで以下を実行する。

```
wsl $ ./createcontainer.bash
```

または

```
wsl $ docker build -t jupyter-mecab .
```

2.01GB。けっこう大きい。
`FROM ubunth:22.04`として少しずつ作ってゆくと900MB程度で収まるかも。

```
docker image list
REPOSITORY             TAG       IMAGE ID       CREATED          SIZE
jupyter-mecab          latest    xxxxxxxx       59 minutes ago   2.01GB
```


# Dockerfile解説

## python + jupyterlabを想定しているため、python環境をベースとして組み立てる。

```
FROM python:3.11
```

## 一部タイムゾーンの設定が必要なパッケージがあることがある（このDockerfile内では不要かも）ので設定しておく。

```
ENV TZ=Asia/Tokyo
```

## Dockerfile内ではapt install は apt update と同じ行に書く

```
RUN apt update && apt -y install .....
```

Dockerfileは行単位で変更の有無を確認されるらしく( https://scrapbox.io/ima1zumi/RUN_apt-get_update_%E3%81%A8_apt-get_install_%E3%81%AF%E3%80%81%E5%90%8C%E4%B8%80%E3%81%AE_RUN_%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89%E5%86%85%E3%81%AB%E3%81%A6%E5%90%8C%E6%99%82%E5%AE%9F%E8%A1%8C%E3%81%99%E3%82%8B )、`apt install`の行が更新されても`apt update`の行が更新されない限りは`apt update`されないまま`apt install`されてしまう。

### RUN apt update && apt install の動作例

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

## mecabコマンドと辞書をインストール

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

## mecabコマンドとmecab-pythonとで必要ファイルのパスを合わせる

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

findしてみると、確かに`/usr/local/etc/mecabrc`は無い。

```
docker $ find / -name mecabrc -print
/etc/mecabrc
```

なので、シンボリックリンクを張る。

```
docker $ ln -s /etc/mecabrc /usr/local/etc/mecabrc
docker $ ls -al /usr/local/etc
lrwxrwxrwx  1 root root   12 Nov 26 08:51 mecabrc -> /etc/mecabrc
```


## jupyterlabを起動する

```
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
wsl $ docker run --name jupyter-mecab-container --rm --detach --publish 8889:8888 --mount type=bind,src=$PWD,dst=/jupyter jupyter-mecab
```

でコンテナ生成して、バックグラウンドで起動。

コンテナ内のport8888と、コンテナ外のport8889を接続する。

コンテナ内の`/jupyter`ディレクトリと、コンテナ外の現在のディレクトリを紐づける。

コンテナ終了したら自動で削除する。


# Windowsからlupyterlabへ

Windowsのブラウザから、( http://localhost:8889/ )へ接続すると、jupyterlabの画面になる。
jupyterlab上の`/jupyter`ディレクトリと`wsl`上のコンテナ生成したディレクトリとで、ファイルのやり取りができる。

** wslのport8889と、windowsのportXXXXを対応付けなきゃ！　と思っていたが、不要のようだ。 **

`wsl`内のファイルは、`windows`から`\\wsl$`でアクセスできる。


# dockerがどうしてもインストールできない場合はwslに適当なディストリビューションをインストールして本件用にしても良いかも

`PowerShell`から、wslにディストリビューションを入れる。

```
PS $ wsl --list --online
インストールできる有効なディストリビューションの一覧を次に示します。
'wsl.exe --install <Distro>' を使用してインストールします。

NAME                                   FRIENDLY NAME
Ubuntu                                 Ubuntu
Debian                                 Debian GNU/Linux
kali-linux                             Kali Linux Rolling
Ubuntu-18.04                           Ubuntu 18.04 LTS
Ubuntu-20.04                           Ubuntu 20.04 LTS
Ubuntu-22.04                           Ubuntu 22.04 LTS
OracleLinux_7_9                        Oracle Linux 7.9
OracleLinux_8_7                        Oracle Linux 8.7
OracleLinux_9_1                        Oracle Linux 9.1
openSUSE-Leap-15.5                     openSUSE Leap 15.5
SUSE-Linux-Enterprise-Server-15-SP4    SUSE Linux Enterprise Server 15 SP4
SUSE-Linux-Enterprise-15-SP5           SUSE Linux Enterprise 15 SP5
openSUSE-Tumbleweed                    openSUSE Tumbleweed
```

メイン環境とおなじものはインストールできないと思うので、そうじゃないものを入れる。

```
PS $ wsl --install Ddebian
　;
  ;
username :
password :
```

今回は新たな環境として`Debian`をインストールしたので、この中で以下のようにインストールを進める。
`venv`は`python`のバージョンと合わせる。

```
wsl $ sudo apt update
wsl $ sudo apt install python3-pip

wsl $ python -V
Python 3.11.2

wsl $ sudo apt install python3.11-venv
wsl $ sudo apt install mecab libmecab-dev mecab-ipadic-utf8
```

本件用のpython環境を作らなければpipインストールできないため、先ほどインストールしたvenvで本件専用環境を準備する。
本件環境は`jupyterlab`というディレクトリ内に作ることにする。

```
wsl $ mkdir jupyterlab
wsl $ cd jupyterlab
wsl $ python3 -m venv venv
wsl $ source venv/bin/activate
(venv) wsl $
```

専用環境を起動できたので、`jupyterlab`, `pandas`, `mecab-python3`を専用環境用にインストールする。

```
(venv) wsl $ pip3 install jupyterlab pandas mecab-python3
```

`jupyterlab`を起動する。

```
(venv) wsl $ jupyter lab &

[I 2023-11-26 12:29:29.047 ServerApp] Package jupyterlab took 0.0000s to import
[I 2023-11-26 12:29:29.058 ServerApp] Package jupyter_lsp took 0.0101s to import
[W 2023-11-26 12:29:29.058 ServerApp] A `_jupyter_server_extension_points` function was not found in jupyter_lsp. Instead, a `_jupyter_server_extension_paths` function was found and will be used for now. This function name will be deprecated in future releases of Jupyter Server.
[I 2023-11-26 12:29:29.062 ServerApp] Package jupyter_server_terminals took 0.0044s to import
[I 2023-11-26 12:29:29.063 ServerApp] Package notebook_shim took 0.0000s to import
[W 2023-11-26 12:29:29.063 ServerApp] A `_jupyter_server_extension_points` function was not found in notebook_shim. Instead, a `_jupyter_server_extension_paths` function was found and will be used for now. This function name will be deprecated in future releases of Jupyter Server.
[I 2023-11-26 12:29:29.063 ServerApp] jupyter_lsp | extension was successfully linked.
[I 2023-11-26 12:29:29.066 ServerApp] jupyter_server_terminals | extension was successfully linked.
[I 2023-11-26 12:29:29.069 ServerApp] jupyterlab | extension was successfully linked.
[I 2023-11-26 12:29:29.257 ServerApp] notebook_shim | extension was successfully linked.
[I 2023-11-26 12:29:29.269 ServerApp] notebook_shim | extension was successfully loaded.
[I 2023-11-26 12:29:29.271 ServerApp] jupyter_lsp | extension was successfully loaded.
[I 2023-11-26 12:29:29.271 ServerApp] jupyter_server_terminals | extension was successfully loaded.
[I 2023-11-26 12:29:29.272 LabApp] JupyterLab extension loaded from /home/xxxx/jupyterlab/venv/lib/python3.11/site-packages/jupyterlab
[I 2023-11-26 12:29:29.272 LabApp] JupyterLab application directory is /home/xxxx/jupyterlab/venv/share/jupyter/lab
[I 2023-11-26 12:29:29.272 LabApp] Extension Manager is 'pypi'.
[I 2023-11-26 12:29:29.274 ServerApp] jupyterlab | extension was successfully loaded.
[I 2023-11-26 12:29:29.274 ServerApp] Serving notebooks from local directory: /home/xxxx/jupyterlab
[I 2023-11-26 12:29:29.274 ServerApp] Jupyter Server 2.10.1 is running at:
[I 2023-11-26 12:29:29.274 ServerApp] http://localhost:8888/lab?token=47520796de5cbead7d301e105e3020c8adc9a9c84005437f
[I 2023-11-26 12:29:29.274 ServerApp]     http://127.0.0.1:8888/lab?token=47520796de5cbead7d301e105e3020c8adc9a9c84005437f
[I 2023-11-26 12:29:29.274 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[W 2023-11-26 12:29:29.773 ServerApp] No web browser found: Error('could not locate runnable browser').
[C 2023-11-26 12:29:29.773 ServerApp]

    To access the server, open this file in a browser:
        file:///home/xxxx/.local/share/jupyter/runtime/jpserver-353-open.html
    Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=47520796de5cbead7d301e105e3020c8adc9a9c84005437f
        http://127.0.0.1:8888/lab?token=47520796de5cbead7d301e105e3020c8adc9a9c84005437f
[I 2023-11-26 12:29:30.057 ServerApp] Skipped non-installed server(s): bash-language-server, dockerfile-language-server-nodejs, javascript-typescript-langserver, jedi-language-server, julia-language-server, pyright, python-language-server, python-lsp-server, r-languageserver, sql-language-server, texlab, typescript-language-server, unified-language-server, vscode-css-languageserver-bin, vscode-html-languageserver-bin, vscode-json-languageserver-bin, yaml-language-server

(venv) wsl $
```

起動して固まるのでEnterキーを押すと、コマンドプロンプトが戻ってくる。
（＆を付けないとコマンドプロンプトにならないが、以後はコマンドプロンプトは使わずブラウザからの操作のため、＆を付けても付けなくても良い）

この画面を放置して、末尾付近にある

```
    Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=47520796de5cbead7d301e105e3020c8adc9a9c84005437f
```

に書いてあるアドレスをWindowsのブラウザに指定すると、jupyterlabにアクセスできる。

