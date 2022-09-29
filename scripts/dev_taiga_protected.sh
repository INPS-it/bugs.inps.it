#!/bin/bash

# Before proceeding make sure you have already activated virtual environment in ./taiga-back/.venv

cd taiga-back
pip install git+https://github.com/kaleidos-ventures/taiga-contrib-protected.git@6.5.0#egg=taiga-contrib-protected
cd ..

cd taiga-protected
git checkout stable
python3 -m venv .venv --prompt taiga-protected
source .venv/bin/activate

pip install -r requirements.txt

cp ../config/env.example .env

# .venv/bin/gunicorn --daemon --workers 4 --timeout 60 --log-level=info --access-logfile taigaprotected.log --bind 127.0.0.1:8003 server:app

pip install uwsgi
.venv/bin/uwsgi --http 127.0.0.1:8003 --module server:app --daemonize taigaprotected.log
