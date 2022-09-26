#!/bin/bash

cd taiga-back
pip install git+https://github.com/kaleidos-ventures/taiga-contrib-protected.git@6.5.0#egg=taiga-contrib-protected
cd ..

cd taiga-protected
git checkout stable
pip install -r requirements.txt
cd ..

cp ./config/env.example ./taiga-protected/.env

cd taiga-protected
../.venv/bin/gunicorn --daemon --workers 4 --timeout 60 --log-level=info --access-logfile - --bind 0.0.0.0:8003 server:app
