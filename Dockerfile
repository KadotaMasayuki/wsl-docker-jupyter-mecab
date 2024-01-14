# base image
FROM python:3.11

# correct time-zone
ENV TZ=Asia/Tokyo

# apt install
RUN apt update && \
  apt -y install mecab libmecab-dev mecab-ipadic-utf8

# apt clear
RUN apt autoremove -y

# pip install
RUN pip3 install --upgrade pip
RUN pip3 install jupyterlab
RUN pip3 install pandas
RUN pip3 install mecab-python3
RUN pip3 install wordcloud

# add link /etc/mecabrc to mecab-python3 target as /usr/local/etc/mecabrc
RUN ln -s /etc/mecabrc /usr/local/etc/mecabrc

# add japanese font
RUN apt install curl unzip
RUN curl -L -o HackGen_v2.9.0.zip https://github.com/yuru7/HackGen/releases/download/v2.9.0/HackGen_v2.9.0.zip
RUN unzip HackGen_v2.9.0.zip
RUN mv HackGen_v2.9.0 /usr/local/share/fonts/HackGen
RUN rm HackGen_v2.9.0.zip

# run jupyter-lab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--LabApp.token=''", "--port=8888"]
