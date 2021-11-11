###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

import time

from django.http import HttpResponseRedirect
from djangosaml2_spid.views import AssertionConsumerServiceView as _ACSV
from django.utils.crypto import get_random_string
from urllib.parse import urlparse
from django.conf import settings
from django.contrib.auth import logout
from django.http import HttpResponseRedirect


class AssertionConsumerServiceView(_ACSV):
    def custom_validation(self, response):
        # eludiamo la validazione spid perche' siamo federati allo IAM proxy inps
        pass

    def post(self, request, attribute_mapping=None, create_unknown_user=None):
        """ SAML Authorization Response endpoint
        """
        response_to_decorate = super(
            AssertionConsumerServiceView, self
        ).post(request, attribute_mapping, create_unknown_user)

        if getattr(response_to_decorate, 'url', None):
            relay_state = response_to_decorate.url
            url_to_redirect = urlparse(relay_state)
            timestamp = int(time.time())
            partial_code = get_random_string(64)
            request.session[partial_code] = str(timestamp)

            new_query = f'partial_code={partial_code}'
            if getattr(url_to_redirect, 'query'):
                new_query += '&' + url_to_redirect.query

            new_url_to_redirect = url_to_redirect._replace(query=new_query)
            decorated_response = HttpResponseRedirect(
                new_url_to_redirect.geturl())
            return decorated_response
        return response_to_decorate


def logout_view(request):
    logout(request)
    return HttpResponseRedirect(getattr(settings, "LOGOUT_REDIRECT_URL", "/"))
