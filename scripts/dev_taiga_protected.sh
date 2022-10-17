#!/bin/bash

cp ./config/protected-config.example ./taiga-protected/.env

cd taiga-protected
git checkout stable
python3 -m venv .venv --prompt taiga-protected
source .venv/bin/activate

pip install -r requirements.txt
pip install uwsgi

uwsgi --http 127.0.0.1:8003 --module server:app --daemonize taigaprotected.log

