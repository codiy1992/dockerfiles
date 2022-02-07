FROM python:latest

USER root

RUN apt-get update

RUN apt-get install -y vim ffmpeg mkvtoolnix

RUN rm -fr /usr/bin/python
RUN ln -sf /usr/local/bin/python /usr/bin/python

RUN wget https://bootstrap.pypa.io/get-pip.py

RUN python get-pip.py

RUN pip install --upgrade pip

RUN pip install ipython

RUN mkdir -p /data

WORKDIR /data
