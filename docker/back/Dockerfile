FROM python:3.9

WORKDIR /

RUN apt-get update
RUN apt-get install -y git

RUN apt-get install -y xmlsec1
RUN apt-get install -y gettext

RUN rm -r -f taiga-back
RUN git clone --branch 6.4.2 https://github.com/kaleidos-ventures/taiga-back.git

RUN pip install -r ./taiga-back/requirements.txt

COPY ./taiga-contrib-inps ./taiga-contrib-inps
COPY ./config ./config

COPY ./config/back-config.py ./taiga-back/settings/config.py

RUN pip install -e ./taiga-contrib-inps/back
RUN pip install -e ./taiga-contrib-inps/spid_inps

COPY ./docker/back/taiga-back.sh taiga-back.sh
RUN chmod +x taiga-back.sh

RUN pip install uwsgi

ENTRYPOINT ["./taiga-back.sh"]
