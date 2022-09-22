#!/bin/bash

CERT_PATH=spid_config/certificates

git clone https://github.com/italia/spid-django.git spid-django
cp -R ./spid-django/example/spid_config ./taiga-back/

mkdir -p /taiga-back/spid_config/attribute_maps
cp  /config/attributes_inps.py /taiga-back/spid_config/attribute_maps/attributes_inps.py

cp  ./taiga-contrib-inps/locale/django.po ./taiga-back/taiga/locale/it/LC_MESSAGES/django.po

cp -R ./taiga-contrib-inps/back/taiga_contrib_inps/ext_templates ./taiga-back/

mkdir -p /taiga-back/$CERT_PATH

cp /certs/public.cert /taiga-back/$CERT_PATH/public.cert
cp /certs/private.key /taiga-back/$CERT_PATH/private.key

cd taiga-back

pip install git+https://github.com/kaleidos-ventures/taiga-contrib-protected.git@6.5.0#egg=taiga-contrib-protected

export DJANGO_SETTINGS_MODULE="settings.config"
python manage.py collectstatic --no-input
python manage.py migrate
python manage.py loaddata --app taiga_contrib_inps inps_initial_project_templates --traceback
python manage.py compilemessages
python manage.py runserver 0.0.0.0:8000
