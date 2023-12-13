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

## python3の必要パッケージをインストールする

```
RUN pip3 install jupyterlab pandas mecab-python3 wordcloud
```

## mecabコマンドとmecab-pythonとで必要ファイルのパスを合わせる

mecabコマンドの`mecabrc`のパスが`/etc/mecabrc`だが、`mecab-python3`は`/usr/local/etc/mecabrc`にあってほしいと望んているため、シンボリックリンクを張る。

```
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

でコンテナ生成。

--name docker ps で見えるコンテナ名を`jupyter-mecab-container`にする

--rm コンテナ終了したら自動で削除する。

--detach バックグラウンドで起動。

--publish コンテナ内のport8888と、コンテナ外のport8889を接続する。

--mount コンテナ内の`/jupyter`ディレクトリと、コンテナ外の現在のディレクトリを紐づける。

jupyter-mecab イメージ`jupyter-mecab`からコンテナを作る


# Windowsからdocker内のlupyterlabへ接続

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

メイン環境と同じものはインストールできないと思うので、そうじゃないものを入れる。

```
PS $ wsl --install Ddebian
インストール中: Debian GNU/Linux
Debian GNU/Linux がインストールされました。
Debian GNU/Linux を起動しています...
Installing, this may take a few minutes...
Please create a default UNIX user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Enter new UNIX username: xxxxx
New password:
Retype new password:
passwd: password updated successfully
Installation successful!
xxxxx@yyyyy:~$ ←以降 ** wsl $ ** と表記
```

今回は新たな環境として`Debian`をインストールしたので、この中で以下のようにインストールを進める。

mecabコマンドをインストールする。

```
wsl $ sudo apt install mecab libmecab-dev mecab-ipadic-utf8
```

pythonが入っていないことを確認。

```
wsl $ python -V
-bash: python: command not found
wsl $ python3 -V
-bash: python3: command not found
```

pythonをインストールする。

```
wsl $ sudo apt update
  ;
wsl $ sudo apt install python3-pip
  ;
```

インストールしたpython3のバージョンを確認する

```
wsl $ python3 -V
Python 3.11.2
```

今回のjupyterlab環境専用にpythonの追加パッケージを準備したいため`venv`を使いたい。
`apt install python3-pip`だけだと以下のようになるので、追加で`venv`をインストールする必要がある。
本件環境は`~/jupyterlab`というディレクトリ内に作ることにする。

```
wsl $ mkdir jupyterlab
wsl $ cd jupyterlab
wsl $ python3 -m venv venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.11-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/xxxxx/jupyterlab/venv/bin/python3
```

venvは`python`のバージョンと合わせる。今回、3.11だったので、`python3.11-venv`を指定する。

```
wsl $ sudo apt install python3.11-venv
```

本件用のpython環境を作らなければpipインストールできないため、先ほどインストールしたvenvで本件専用環境を準備する。
先ほど試した通り、本件環境は`~/jupyterlab`というディレクトリ内に作ることにする。

```
wsl $ mkdir jupyterlab （済）
wsl $ cd jupyterlab （済）
wsl $ python3 -m venv venv
wsl $ source venv/bin/activate
(venv) wsl $
```

専用環境を起動できたので、`jupyterlab`, `pandas`, `mecab-python3`を専用環境用にインストールする。

```
(venv) wsl $ pip3 install jupyterlab pandas mecab-python3 wordcloud
```

もし、次のような警告が出た場合はproxyを指定してやってみる

```
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:992)'))': /simple/jupyterlab/
```

proxyを指定してもういちど。アドレスとポートは自分の環境に合わせて。

```
(venv) wsl $ pip3 --proxy=aaa.bbb.ccc.ddd:eeee install jupyterlab pandas mecab-python3 wordcloud
```

dockerでの手順に書いた通り、mecabコマンドとmecab-pythonとのファイルパスの不整合があるので、解消しておく。

```
(venv) wsl $ ln -s /etc/mecabrc /usr/local/etc/mecabrc
```

これでpythonでmecabが利用できるようになった。

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

この画面の末尾付近にある

```
    Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=47520796de5cbead7d301e105e3020c8adc9a9c84005437f
```

に書いてあるアドレスをWindowsのブラウザに指定すると、jupyterlabにアクセスできる。


## word cloudに日本語を表示する場合

日本語をワードクラウドにすると、豆腐（□）が表示されて話にならない。

```
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
wc = WordCloud()
wc.generate("あ い う え お あ あ あ い え")
```

そこで、以下のようにWindows内の日本語フォントを指定すると、、、

```
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
font_path = "/mnt/C/Windows/Fonts/meiryo.ttc"
wc = WordCloud(font_path=font_path)
wc.generate("あ い う え お あ あ あ い え")
```

以下のようなわかりづらい大量のエラーメッセージとともに、フォント取得に失敗してエラーになる。

```
File ~/jupyterlab/venv/lib/python3.11/site-packages/PIL/ImageFont.py:797, in truetype(font, size, index, encoding, layout_engine)
    794     return FreeTypeFont(font, size, index, encoding, layout_engine)
    796 try:
--> 797     return freetype(font)
    798 except OSError:
    799     if not is_path(font):
```

jupyterlabを起動するディレクトリより上に遡って探索できないようだ。
そこで、jupyterlabを起動するディレクトリ以下に日本語フォントを置くことで解決できる。
たとえば ` 白源 (はくげん) フォント ( https://github.com/yuru7/HackGen/ ) ` を用いて、以下のように配置する。

```
jupyterlab/
  + font/
     + HackGen_vXXXX.zip
     + HackGen_vXXXX/
         + HackGen-Bold.ttf
         + HackGen-Regular.ttf
         +    ;
```

wsl上で操作する場合は jupyterlab ディレクトリ内で以下のようにする。

```
# fontディレクトリを作る
wsl $ mkdir font
# fontディレクトリに移動する
wsl $ cd font
# フォントをダウンロードするためにcurl をインストールする
wsl $ sudo apt install curl
# curlでhttpsアクセスするときSSLが邪魔することがあるので -k オプションで無視する（良くない）
# リンクの先であちこちにたらい回しされることがあるので -L オプションで最後まで辿って取得する
wsl $ curl -k -L https://github.com/yuru7/HackGen/releases/download/v2.9.0/HackGen_v2.9.0.zip
# zip ファイルを解凍する必要があるので解凍コマンドをインストールする
wsl $ sudo apt install unzip
# 解凍する
wsl $ unzip HackGen_v2.9.0.zip
# 解凍結果をみてみる
wsl $ ls
HackGen_v2.9.0
# 解答結果のディレクトリの中身を見てみる
wsl $ ls HackGen_v2.9.0
HackGen-Bold.ttf
HackGen-Regular.ttf
  ;
  ;
# fontディレクトリの上にもどる
wsl $ cd ..
# venv環境にする
wsl $ source venv/bin/activete
# jupyterlabをバックグラウンドで起動する
(venv) wsl $ jupyter lab &
```

または、Windows上でマウス操作で次のようにすることもできる。

1. フォントをダウンロード ( https://github.com/yuru7/HackGen/ ) して解凍する
2. Win+R で`ファイル名を指定して実行`の画面を開き、`\\wsl$\Debian\home\Debianをインストールした時に設定した名前\jupyterlab` と入力しOKを押して、jupyterlabのディレクトリを開く（\\wsl$　とだけ入力してディレクトリを開いて、あとはマウス操作で辿っても良い )
3. jupyterlab ディレクトリの中に font ディレクトリを作成
4. font ディレクトリの中に HackGen_vXXXX ディレクトリを作成
5. HackGen_vXXX ディレクトリの中に、解凍した HackGen-Regular.ttf を置く
6. wsl上で、 `wsl $ source venv/bin/activate` してから `(venv) wsl $ jupyter lab &` でjupyterlabを起動する

wsl上、またはwindows上で、上記の操作をしてフォントを入れたら、jupyterlab上で次のように書くと、動く。

```
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
font_path = "font/HackGen_v2.9.0/HackGen-Regular.ttf"
wc = WordCloud(font_path=font_path)
wc.generate("あ い う え お あ あ あ い え")
```


# (参考) wsl piplist

```
(venv) wsl $ pip3 list
```

```
Package                   Version
------------------------- ------------
anyio                     4.1.0
argon2-cffi               23.1.0
argon2-cffi-bindings      21.2.0
arrow                     1.3.0
asttokens                 2.4.1
async-lru                 2.0.4
attrs                     23.1.0
Babel                     2.13.1
beautifulsoup4            4.12.2
bleach                    6.1.0
certifi                   2023.11.17
cffi                      1.16.0
charset-normalizer        3.3.2
comm                      0.2.0
contourpy                 1.2.0
cycler                    0.12.1
debugpy                   1.8.0
decorator                 5.1.1
defusedxml                0.7.1
executing                 2.0.1
fastjsonschema            2.19.0
fonttools                 4.46.0
fqdn                      1.5.1
idna                      3.6
ipykernel                 6.27.1
ipython                   8.18.1
isoduration               20.11.0
jedi                      0.19.1
Jinja2                    3.1.2
json5                     0.9.14
jsonpointer               2.4
jsonschema                4.20.0
jsonschema-specifications 2023.11.1
jupyter_client            8.6.0
jupyter_core              5.5.0
jupyter-events            0.9.0
jupyter-lsp               2.2.1
jupyter_server            2.11.1
jupyter_server_terminals  0.4.4
jupyterlab                4.0.9
jupyterlab_pygments       0.3.0
jupyterlab_server         2.25.2
kiwisolver                1.4.5
MarkupSafe                2.1.3
matplotlib                3.8.2
matplotlib-inline         0.1.6
mecab-python3             1.0.8
mistune                   3.0.2
nbclient                  0.9.0
nbconvert                 7.11.0
nbformat                  5.9.2
nest-asyncio              1.5.8
notebook_shim             0.2.3
numpy                     1.26.2
overrides                 7.4.0
packaging                 23.2
pandas                    2.1.3
pandocfilters             1.5.0
parso                     0.8.3
pexpect                   4.9.0
Pillow                    10.1.0
pip                       23.0.1
platformdirs              4.0.0
prometheus-client         0.19.0
prompt-toolkit            3.0.41
psutil                    5.9.6
ptyprocess                0.7.0
pure-eval                 0.2.2
pycparser                 2.21
Pygments                  2.17.2
pyparsing                 3.1.1
python-dateutil           2.8.2
python-json-logger        2.0.7
pytz                      2023.3.post1
PyYAML                    6.0.1
pyzmq                     25.1.1
referencing               0.31.0
requests                  2.31.0
rfc3339-validator         0.1.4
rfc3986-validator         0.1.1
rpds-py                   0.13.1
Send2Trash                1.8.2
setuptools                66.1.1
six                       1.16.0
sniffio                   1.3.0
soupsieve                 2.5
stack-data                0.6.3
terminado                 0.18.0
tinycss2                  1.2.1
tornado                   6.3.3
traitlets                 5.14.0
types-python-dateutil     2.8.19.14
tzdata                    2023.3
uri-template              1.3.0
urllib3                   2.1.0
wcwidth                   0.2.12
webcolors                 1.13
webencodings              0.5.1
websocket-client          1.6.4
wordcloud                 1.9.2
```

