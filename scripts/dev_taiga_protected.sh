#!/bin/bash

cp ./config/protected-config.example ./taiga-protected/.env

cd taiga-protected
git checkout stable

pip install -r requirements.txt
pip install uwsgi

uwsgi --http 127.0.0.1:8003 --module server:app --daemonize taigaprotected.log
