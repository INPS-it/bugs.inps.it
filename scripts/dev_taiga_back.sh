#!/bin/bash

CERT_PATH=./spid_config/certificates

cp ./config/back-config.py ./taiga-back/settings/config.py

git clone https://github.com/italia/spid-django.git spid-django
cp -R ./spid-django/example/spid_config ./taiga-back/

mkdir -p ./taiga-back/spid_config/attribute_maps
cp  ./config/attributes_inps.py ./taiga-back/spid_config/attribute_maps/attributes_inps.py

cp  ./taiga-contrib-inps/locale/django.po ./taiga-back/taiga/locale/it/LC_MESSAGES/django.po

cp -R ./taiga-contrib-inps/back/taiga_contrib_inps/ext_templates ./taiga-back/

cd taiga-back
pip install -r requirements.txt
pip install git+https://github.com/kaleidos-ventures/taiga-contrib-protected.git@6.5.0#egg=taiga-contrib-protected
cd ../

pip install -e ./taiga-contrib-inps/back
pip install -e ./taiga-contrib-inps/spid_inps

cd taiga-back
rm -R $CERT_PATH
mkdir $CERT_PATH && cd "$_"

spid-compliant-certificates generator \
    --key-size 3072 \
    --common-name "A.C.M.E" \
    --days 365 \
    --entity-id https://spid.acme.it \
    --locality-name Roma \
    --org-id "PA:IT-c_h501" \
    --org-name "A Company Making Everything" \
    --sector public \
    --key-out private.key \
    --crt-out public.cert

cd ../../

export SPID_SAML_CHECK_IDP_ACTIVE=False
export SPID_DEMO_IDP_ACTIVE=False
export DJANGO_SETTINGS_MODULE="settings.config"
python manage.py collectstatic --noinput
python manage.py migrate
python manage.py loaddata --app taiga_contrib_inps inps_initial_project_templates --traceback
python manage.py compilemessages
# don't use this in production, use a pure uwsgi socket instead !
python manage.py runserver

# or
# SPID_SAML_CHECK_IDP_ACTIVE=True uwsgi --http-keepalive --https 0.0.0.0:8000,$CERT_PATH/public.cert,$CERT_PATH/private.key --module taiga.wsgi:application --env settings.config --chdir . --honour-stdin
