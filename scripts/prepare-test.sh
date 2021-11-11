#!/bin/bash

./scripts/init_taiga_dev.sh

CERT_PATH=./spid_config/certificates

git clone https://github.com/italia/spid-django.git spid-django
cp -R ./spid-django/example/spid_config ./taiga-back/

cd taiga-back
pip install -r requirements.txt
pip install -r requirements-tests.txt
pip install -r requirements-devel.txt
cd ../

pip install -e ./taiga-contrib-inps/spid_inps
