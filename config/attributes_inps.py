from django.conf import settings

ATTRS = settings.SPID_REQUIRED_ATTRIBUTES


MAP = {
    "identifier": "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
    "fro": {k: k for k in ATTRS},
    "to": {k: k for k in ATTRS},
}
