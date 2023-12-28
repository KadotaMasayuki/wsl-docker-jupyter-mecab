# dockerがどうしてもインストールできない場合は、wslをコンテナ扱いして運用してみる。

*wsl-jupyter (no docker)*

Windows11 > WSL2 > Debian > venv > Jupyterlab という構成でjupyterlab環境を作成。

Windows上のブラウザから http//localhost:8888/ へアクセスするとwsl->jupyterlab:8888へ接続しJupyterlabを利用できる。

python3.11とvenvの環境で、mecabとwordcloudを使えるようにしてある。

## コマンドラインの表記

- `PS > ` は、Windows上のPowerShellのコマンドラインを示す
- `wsl $ ` は、wsl上のコマンドラインを示す
- `(venv) wsl $ ` は、venv環境でのwsl上のコマンドラインを示す

## ディレクトリ構成

wsl中に以下のような構成を想定。

```
~/
  jupyterlab/
    + ソースコード１
    + ソースコード２
        ;
/usr/local/share/fonts/truetyper/HackGen/
    + HackGen_vXXXX.zip
    + HackGen_vXXXX/
    + HackGen-Bold.ttf
    + HackGen-Regular.ttf
    +    ;
```

# express : とにかくインストールする

## wsl (debian) をインストール

### インストールできるディストリビューション一覧を取得

```
PS > wsl --list --online
  ;
NAME                                   FRIENDLY NAME
Debian                                 Debian GNU/Linux
  ;
```

### Debianをインストール

```
PS > wsl --install Ddebian
  ;
Enter new UNIX username: xxxxx
New password:
Retype new password:
passwd: password updated successfully
Installation successful!

wsl $
```

## proxy環境下であればproxy環境変数を設定

https://github.com/KadotaMasayuki/wsl-docker?tab=readme-ov-file#wsl%E4%B8%8A%E3%81%AElinux%E3%81%A7%E3%81%AE%E4%BD%9C%E6%A5%ADproxy%E7%92%B0%E5%A2%83%E5%A4%89%E6%95%B0%E3%82%92%E8%A8%AD%E5%AE%9A%E3%81%99%E3%82%8Bproxy%E7%92%B0%E5%A2%83%E4%B8%8B%E3%81%A7%E3%81%AF%E3%81%AA%E3%81%84%E5%A0%B4%E5%90%88%E3%81%AF%E4%B8%8D%E8%A6%81


## 日本語フォントをインストール

```
wsl $ cd ~/
wsl $ mkdir font
wsl $ cd font
wsl $ sudo apt update
  ;
wsl $ sudo apt install curl unzip
wsl $ curl -k -L https://github.com/yuru7/HackGen/releases/download/v2.9.0/HackGen_v2.9.0.zip
wsl $ unzip HackGen_v2.9.0.zip
wsl $ ls HackGen_v2.9.0
HackGen-Bold.ttf
HackGen-Regular.ttf
  ;
wsl $ sudo mkdir /usr/local/share/fonts/truetype/HackGen
wsl $ sudo cp HackGen_v2.9.0/* /usr/local/share/fonts/truetype/HackGen/
  ;
wsl $ cd ..
```

## mecabをインストール

```
wsl $ sudo apt install mecab libmecab-dev mecab-ipadic-utf8
```

## python3をインストール

pythonが入っていないことを確認する。

```
wsl $ python -V
-bash: python: command not found
wsl $ python3 -V
-bash: python3: command not found
```

python3をインストールする。

```
wsl $ sudo apt install python3-pip
  ;
```

## python3用のvenvをインストール

インストールしたpython3のバージョンを確認する

```
wsl $ python3 -V
Python 3.11.2
```

python3のバージョンに合わせたvenvをインストールする

```
wsl $ sudo apt install python3.11-venv
```

## jupyterlabでの作業環境を作る

### jupyterlab用のディレクトリを作りvenvする

```
wsl $ cd ~/
wsl $ mkdir jupyterlab
wsl $ cd jupyterlab
wsl $ python3 -m venv venv
wsl $ source venv/bin/activate
(venv) wsl $
```

### jupyterlab用のpythonパッケージをインストールする

`jupyterlab`, `pandas`, `mecab-python3`をインストールする。

```
(venv) wsl $ pip3 install jupyterlab pandas mecab-python3 wordcloud
```

もし、次のような警告が出た場合はproxyを指定してやってみる

```
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:992)'))': /simple/jupyterlab/
```

proxyをコマンド中で指定する場合は以下の通り。

```
(venv) wsl $ pip3 --proxy=aaa.bbb.ccc.ddd:eeee install jupyterlab pandas mecab-python3 wordcloud
```

## mecabコマンドとmecab-pythonとのファイルパスの不整合を解消

```
(venv) wsl $ ln -s /etc/mecabrc /usr/local/etc/mecabrc
```

## 使ってみる

`jupyterlab`を起動する。

```
(venv) wsl $ jupyter lab &
  ;
    To access the server, open this file in a browser:
        file:///home/xxxx/.local/share/jupyter/runtime/jpserver-353-open.html
    Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=oiuhrj30897gq9876erasd7ag6a93
        http://127.0.0.1:8888/lab?token=oiuhrj30897gq9876erasd7ag6a93
[I 2023-11-26 12:29:30.057 ServerApp] Skipped non-installed server(s): bash-language-server, dockerfile-language-server-nodejs, javascript-typescript-langserver, jedi-language-server, julia-language-server, pyright, python-language-server, python-lsp-server, r-languageserver, sql-language-server, texlab, typescript-language-server, unified-language-server, vscode-css-languageserver-bin, vscode-html-languageserver-bin, vscode-json-languageserver-bin, yaml-language-server

(venv) wsl $
```

この画面の末尾付近にある

```
    Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=oiuhrj30897gq9876erasd7ag6a93
```

に書いてあるアドレスをWindowsのブラウザに指定すると、jupyterlabにアクセスできる。

## word cloudで日本語画像を作る

jupyterlabのノートに以下を記入して実行すると、それなりのワードクラウドが表示される。

```
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
wc = WordCloud()
wc.generate("あ い う あ あ え あ お あ あ あ い え あ か あ あ く あ そ あ")
plt.imshow(wc)
wc.to_file("wordcloud.png")
```

# 解説付き

## wslにLinuxディストリビューションをインストール

`PowerShell`から、wslにディストリビューションを入れる。

### インストールできるディストリビューション一覧を取得

```
PS > wsl --list --online
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

### Debianを入れる

すでにUbuntu環境があるので、それとは違うものを入れる。ここではDebianにした。

```
PS > wsl --install Ddebian
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

wsl $
```

今回は新たな環境として`Debian`をインストールしたので、この中で以下のようにインストールを進める。

## mecabコマンドをインストール

```
wsl $ sudo apt update
  ;
wsl $ sudo apt install mecab libmecab-dev mecab-ipadic-utf8
```

## python3をインストール

pythonが入っていないことを確認。

```
wsl $ python -V
-bash: python: command not found
wsl $ python3 -V
-bash: python3: command not found
```

python3をインストールする。

```
wsl $ sudo apt install python3-pip
  ;
```

## jupyterlab環境をつくる

wsl上に、今回のjupyterlab専用の仮想環境を~/jupyterlabディレクトリ内に専用環境を構築したいため、ディレクトリを用意する。

```
wsl $ mkdir jupyterlab
wsl $ cd jupyterlab
```

## jupyterlab環境をvenvで作る

このディレクトリで`venv`すると・・

```
wsl $ python3 -m venv venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.11-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/xxxxx/jupyterlab/venv/bin/python3
```

とエラーが出る。venvを使うならpython3.11-venvをインストールせよ、というメッセージ。

## python3用のvenvをインストール

念のため、インストールしたpython3のバージョンを確認する

```
wsl $ python3 -V
Python 3.11.2
```

先ほどのメッセージに従って、インストールする。
venvは`python`のバージョンと合わせる。今回、3.11なので、`python3.11-venv`を指定する。

```
wsl $ sudo apt install python3.11-venv
```

## あらためて、jupyterlabでの作業環境を作る

インストールしたvenvで本件専用環境を準備する。
先ほど試した通り、本件環境は`~/jupyterlab`というディレクトリ内に作ることにする。

```
wsl $ mkdir jupyterlab （済）
wsl $ cd jupyterlab （済）
wsl $ python3 -m venv venv
wsl $ source venv/bin/activate
(venv) wsl $
```

専用環境を起動できると、コマンドラインの先頭に仮想環境の名前が表示される。ここでは`(venv)`。

### jupyterlab用のpythonパッケージをインストールする

専用環境になっていることを確認し、`jupyterlab`, `pandas`, `mecab-python3`を専用環境用にインストールする。

```
(venv) wsl $ pip3 install jupyterlab pandas mecab-python3 wordcloud
```

もし、次のような警告が出た場合はproxyを指定してやってみる。

```
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:992)'))': /simple/jupyterlab/
```

wslにproxy環境変数を設定する場合は以下を参考に。

https://github.com/KadotaMasayuki/wsl-docker?tab=readme-ov-file#wsl%E4%B8%8A%E3%81%AElinux%E3%81%A7%E3%81%AE%E4%BD%9C%E6%A5%ADproxy%E7%92%B0%E5%A2%83%E5%A4%89%E6%95%B0%E3%82%92%E8%A8%AD%E5%AE%9A%E3%81%99%E3%82%8Bproxy%E7%92%B0%E5%A2%83%E4%B8%8B%E3%81%A7%E3%81%AF%E3%81%AA%E3%81%84%E5%A0%B4%E5%90%88%E3%81%AF%E4%B8%8D%E8%A6%81

proxyをコマンド中で指定する場合は以下の通り。

```
(venv) wsl $ pip3 --proxy=aaa.bbb.ccc.ddd:eeee install jupyterlab pandas mecab-python3 wordcloud
```

## mecabコマンドとmecab-pythonとのファイルパスの不整合を解消

dockerでの手順に書いた通り、mecabコマンドとmecab-pythonとのファイルパスの不整合があるので、解消しておく。

```
(venv) wsl $ ln -s /etc/mecabrc /usr/local/etc/mecabrc
```

## 使ってみる

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
（＆を付けないとコマンドプロンプトに戻ってこないが、以後はコマンドプロンプトは使わずブラウザからの操作のため、＆を付けても付けなくても良い）

この画面の末尾付近にある

```
    Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=47520796de5cbead7d301e105e3020c8adc9a9c84005437f
```

に書いてあるアドレスをWindowsのブラウザに指定すると、jupyterlabにアクセスできる。

## word cloudに日本語を表示する

日本語をワードクラウドにすると、豆腐（□）が表示されて話にならない。
たとえば以下のように書くと、表示される画像は□だらけになる。

```
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
wc = WordCloud()
wc.generate("あ い う え お あ あ あ い え")
plt.imshow(wc)
wc.to_file("wordcloud.png")
```

そこで、以下のようにWindows内の日本語フォント`/mnt/C/Windows/Fonts/meiryo.ttc`（メイリオ）を指定すると、、、

```
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
font_path = "/mnt/C/Windows/Fonts/meiryo.ttc"
wc = WordCloud(font_path=font_path)
wc.generate("あ い う え お あ あ あ い え")
plt.imshow(wc)
wc.to_file("wordcloud.png")
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

jupyterlab上でフォントの一覧を取得してみると・・

```
import matplotlib.font_manager as fm
fm.findSystemFonts()
['DejaVuSansMono-Bold.ttf', 'DejaVuSansMono.ttf', 'DejaVuSans.ttf', 'DejaVuSans-Bold.ttf', 'DejaVuSerif.ttf', 'DejaVuSerif-Bold.ttf']
```

DejaVu... というフォントは `/usr/local/share/fonts/truetype/dejavu/` に入っている。

このパス以外のフォントは、jupyterlabのソースコードファイルより上のディレクトリに遡って探索できないようだ？？

ということはソースコードと同じフォルダに配置するか、/usr/local/share/fonts/truetype/...に配置すると良さそう。

たとえば ` 白源 (はくげん) フォント ( https://github.com/yuru7/HackGen/ ) ` を用いて、以下のように配置する。

```
jupyterlab/
  + ソースコード１
  + ソースコード２
      ;
  + font/
     + HackGen_vXXXX.zip
     + HackGen_vXXXX/
         + HackGen-Bold.ttf
         + HackGen-Regular.ttf
         +    ;
```

または、
```
/usr/local/share/fonts/truetype/
     + HackGen/
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
# /usr/local/share/fonts/truetype/HackGen/を作り、そこにコピーする
wsl $ sudo mkdir /usr/local/share/fonts/truetype/HackGen
wsl $ sudo cp HackGen_v2.9.0/* /usr/local/share/fonts/truetype/HackGen/
  ;
# fontディレクトリの上（jupyterlabディレクトリ）に戻る
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
6. wsl上で、jupyterlabディレクトリ内で、 `wsl $ source venv/bin/activate` してから `(venv) wsl $ jupyter lab &` でjupyterlabを起動する

wsl上、またはwindows上で、上記の操作をしてフォントを入れてjupyterlabを起動したら、jupyterlab上で次のように書くと、動く。

```
# フォント一覧
import matplotlib.font_manager as fm
fm.findSystemFonts()

# ワードクラウド
from wordcloud import WordCloud
import matplotlib.pyplot as plt
%matplotlib inline
font_path = "font/HackGen_v2.9.0/HackGen-Regular.ttf" # または font_path = "HackGen-Regular.ttf"
wc = WordCloud(font_path=font_path)
wc.generate("あ い う え お あ あ あ い え")
plt.imshow(wc)

# 作ったワードクラウドをファイルに保存
wc.to_file("wordcloud.png")
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

以上

