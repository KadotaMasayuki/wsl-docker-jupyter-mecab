# base image
FROM python:3.11

# correct time-zone
ENV TZ=Asia/Tokyo

# apt install
RUN apt update && \
  apt -y install python3-pip python3.11-venv mecab libmecab-dev mecab-ipadic-utf8

# pip install
RUN pip3 install --upgrade pip
RUN pip3 install jupyterlab
RUN pip3 install pandas
RUN pip3 install mecab-python3

# apt clear
RUN apt autoremove -y

# add link /etc/mecabrc to mecab-python3 target as /usr/local/etc/mecabrc
RUN ln -s /etc/mecabrc /usr/local/etc/mecabrc

# run jupyter-lab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--LabApp.token=''", "--port=8888"]
