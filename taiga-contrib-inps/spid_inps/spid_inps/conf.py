###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

import saml2
import logging
from saml2.config import SPConfig
from typing import Optional
import copy
from django.http import HttpRequest
from django.conf import settings
from django.urls import reverse
from urllib.parse import urljoin

logger = logging.getLogger("spid_inps")


def config_settings_loader(request: Optional[HttpRequest] = None) -> SPConfig:
    conf = SPConfig()
    if request is None:
        # Not a SPID request: load SAML_CONFIG unchanged
        conf.load(copy.deepcopy(settings.SAML_CONFIG))
        return conf

    # Build a SAML_CONFIG for SPID
    base_url = settings.SPID_BASE_URL or request.build_absolute_uri("/")
    metadata_url = urljoin(base_url, settings.SPID_METADATA_URL_PATH)

    if settings.SPID_METADATA_URL_PATH in request.get_full_path():
        _REQUIRED_ATTRIBUTES = settings.SPID_REQUIRED_ATTRIBUTES
        _OPTIONAL_ATTRIBUTES = settings.SPID_OPTIONAL_ATTRIBUTES
    else:
        _REQUIRED_ATTRIBUTES = settings.CIE_REQUIRED_ATTRIBUTES
        _OPTIONAL_ATTRIBUTES = []

    saml_config = {
        "entityid": getattr(settings, 'SAML2_ENTITY_ID', metadata_url),
        "attribute_map_dir": settings.SPID_ATTR_MAP_DIR,
        "service": {
            "sp": {
                "name": metadata_url,
                "name_qualifier": base_url,
                "name_id_format": [settings.SPID_NAMEID_FORMAT],
                "endpoints": {
                    "assertion_consumer_service": [
                        (
                            urljoin(base_url, reverse(
                                "djangosaml2_spid:saml2_acs")),
                            saml2.BINDING_HTTP_POST,
                        ),
                    ],
                    "single_logout_service": [
                        (
                            urljoin(
                                base_url, reverse(
                                    "djangosaml2_spid:saml2_ls_post")
                            ),
                            saml2.BINDING_HTTP_POST,
                        ),
                    ],
                },
                # Mandates that the IdP MUST authenticate the presenter directly
                # rather than rely on a previous security context.
                "force_authn": False,  # SPID
                "name_id_format_allow_create": False,
                # attributes that this project need to identify a user

                "required_attributes": _REQUIRED_ATTRIBUTES,
                "optional_attributes": _OPTIONAL_ATTRIBUTES,

                "requested_attribute_name_format": saml2.saml.NAME_FORMAT_BASIC,
                "name_format": saml2.saml.NAME_FORMAT_BASIC,
                "signing_algorithm": settings.SPID_SIG_ALG,
                "digest_algorithm": settings.SPID_DIG_ALG,
                "authn_requests_signed": True,
                "logout_requests_signed": True,
                # Indicates that Authentication Responses to this SP must
                # be signed. If set to True, the SP will not consume
                # any SAML Responses that are not signed.
                "want_assertions_signed": True,
                "want_response_signed": False,
                # When set to true, the SP will consume unsolicited SAML
                # Responses, i.e. SAML Responses for which it has not sent
                # a respective SAML Authentication Request. Set to True to
                # let ACS endpoint work.
                "allow_unsolicited": settings.SAML_CONFIG.get(
                    "allow_unsolicited", False
                ),
                # Permits to have attributes not configured in attribute-mappings
                # otherwise...without OID will be rejected
                "allow_unknown_attributes": True,
            },
        },
        "disable_ssl_certificate_validation": settings.SAML_CONFIG.get(
            "disable_ssl_certificate_validation"
        ),
        "metadata": {
            "local": [settings.SPID_IDENTITY_PROVIDERS_METADATA_DIR],
            "remote": [],
        },
        "accepted_time_diff": settings.SAML_CONFIG.get(
            "accepted_time_diff", 0
        ),
        # Signing
        "key_file": settings.SPID_PRIVATE_KEY,
        "cert_file": settings.SPID_PUBLIC_CERT,
        # Encryption
        "encryption_keypairs": [
            {
                "key_file": settings.SPID_PRIVATE_KEY,
                "cert_file": settings.SPID_PUBLIC_CERT,
            }
        ],
        "organization": copy.deepcopy(settings.SAML_CONFIG["organization"]),
    }

    if settings.SAML_CONFIG.get("debug"):
        saml_config["debug"] = True

    if "xmlsec_binary" in settings.SAML_CONFIG:
        saml_config["xmlsec_binary"] = copy.deepcopy(
            settings.SAML_CONFIG["xmlsec_binary"]
        )
    else:
        saml_config["xmlsec_binary"] = get_xmlsec_binary(
            ["/opt/local/bin", "/usr/bin/xmlsec1"]
        )

    if settings.SPID_SAML_CHECK_IDP_ACTIVE:
        saml_config["metadata"]["remote"].append(
            {"url": settings.SPID_SAML_CHECK_METADATA_URL}
        )

    if settings.SPID_DEMO_IDP_ACTIVE:
        saml_config["metadata"]["remote"].append(
            {"url": settings.SPID_DEMO_METADATA_URL}
        )

    if settings.SPID_VALIDATOR_IDP_ACTIVE:
        saml_config["metadata"]["remote"].append(
            {"url": settings.SPID_VALIDATOR_METADATA_URL}
        )

    logger.debug(f"SAML_CONFIG: {saml_config}")
    conf.load(saml_config)
    return conf
