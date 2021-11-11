###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from settings.common import *
import os

SKIP_SOUTH_TESTS = True
SOUTH_TESTS_MIGRATE = False
CELERY_ALWAYS_EAGER = True
CELERY_ENABLED = False

MEDIA_ROOT = "/tmp"

EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
INSTALLED_APPS = INSTALLED_APPS + [
    "taiga_contrib_inps",
    "djangosaml2_spid",
    'spid_config'
]

if 'spid_config' in INSTALLED_APPS:
    from spid_config.spid_settings import *
    SPID_CERTS_DIR = os.path.join(BASE_DIR, 'spid_config', 'certificates')
    SPID_PUBLIC_CERT = os.path.join(SPID_CERTS_DIR, 'public.cert')
    SPID_PRIVATE_KEY = os.path.join(SPID_CERTS_DIR, 'private.key')
    # https only
    CSRF_COOKIE_SECURE = True
    CSRF_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SECURE = True
    STATIC_URL = "/static/"
    SPID_BASE_URL = "https://localhost/"
    LOGOUT_REDIRECT_URL = '/'
    SPID_SAML_CHECK_METADATA_URL = os.environ.get(
        'SPID_SAML_CHECK_METADATA_URL', 'https://spid-saml-check:8080/metadata.xml')
    SPID_DEMO_METADATA_URL = os.environ.get(
        'SPID_DEMO_METADATA_URL', 'https://spid-saml-check:8080/demo/metadata.xml')
    LOGIN_REDIRECT_URL = 'https://localhost/post_login'
    SPID_ACS_URL_PATH = 'spid/acs/'

ONLY_SUPERUSER_CAN_CREATE_PROJECT = True

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'taiga_test'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASS', 'postgres'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

MAX_UPLOAD_FILE_SIZE = 10485760
ATTACHMENT_MIME_TYPES = ["image/jpg",
                         "image/jpeg", "image/png", "application/pdf"]
