###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###




from .serializers import ExtUserAdminSerializer


def ext_make_auth_response_data(user):
    serializer = ExtUserAdminSerializer(user)
    data = dict(serializer.data)

    from taiga.auth.tokens import RefreshToken
    refresh = RefreshToken.for_user(user)

    data['refresh'] = str(refresh)
    data['auth_token'] = str(refresh.access_token)

    return data
