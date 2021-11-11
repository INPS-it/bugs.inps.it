###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.contrib.auth import get_user_model
from djangosaml2.backends import Saml2Backend
import logging
import uuid
from django.conf import settings
from .models import Person

logger = logging.getLogger(__name__)


class TaigaInpsSpidSaml2Backend(Saml2Backend):
    """
        SPID Taiga Inps SAML2 Backend
    """

    def authenticate(self, request, session_info=None,
                     attribute_mapping=None, create_unknown_user=True,
                     assertion_info=None, **kwargs):
        if session_info is None or attribute_mapping is None:
            logger.info('Session info or attribute mapping are None')
            return None

        if 'ava' not in session_info:
            logger.error('"ava" key not found in session_info')
            return None

        idp_entityid = session_info['issuer']
        attributes = self.clean_attributes(session_info['ava'], idp_entityid)

        logger.debug(f'attributes: {attributes}')

        if not self.is_authorized(attributes, attribute_mapping, idp_entityid, assertion_info):
            logger.error(f'Request not authorized from {idp_entityid}')
            return None

        email = attributes.get('email', [''])[0]
        if not email:
            logger.error(
                f'"email" attribute not available from {idp_entityid}')
            return None

        person = Person.objects.filter(
            tin=attributes.get('codiceFiscale', [''])[0],
            user__is_active=True
        ).first() if getattr(settings, 'USE_ACCOUNT_LINKING_USER_PERSON', False) else None

        if person:
            user = person.user
            if idp_entityid != person.issuer:
                person.issuer = idp_entityid
                person.save()

        elif getattr(settings, 'SAML_CREATE_UNKNOWN_USER', True):
            # account linking based on email
            user = get_user_model().objects.filter(email=email).first()

            if not user:
                # create user with attributes
                username = uuid.uuid4().hex
                full_name = getattr(
                    settings, 'USER_FULLNAME_PREFIX', 'User_') + username
                user = get_user_model().objects.create(
                    username=username, email=email, full_name=full_name)

            if user and getattr(settings, 'SAVE_PERSON_FISCAL_NUMBER', False):
                person_tin = attributes.get('codiceFiscale', [''])[0]
                Person.objects.update_or_create(
                    user=user, defaults={
                        "tin": person_tin, "issuer": idp_entityid}
                )

        if self.user_can_authenticate(user):
            return user
