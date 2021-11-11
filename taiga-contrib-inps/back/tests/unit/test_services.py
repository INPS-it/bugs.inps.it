###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from tests.factories import UserFactory
from ...taiga_contrib_inps.services import ext_make_auth_response_data


def refresh_token_mock(user):
    d = {'access_token': 'test-value'}
    return SimpleNamespace(**d)


def test_ext_make_auth_response_data():
    '''Test the can_create_project attribute to FE'''

    with patch("taiga.auth.tokens.RefreshToken.for_user", refresh_token_mock):

        super_user = UserFactory.build()
        super_user.is_superuser = True

        user = UserFactory.build()
        user.is_superuser = False

        with patch('django.conf.settings.ONLY_SUPERUSER_CAN_CREATE_PROJECT', True):
            data = ext_make_auth_response_data(super_user)
            assert "can_create_project" in data
            assert data['can_create_project']

            data = ext_make_auth_response_data(user)
            assert "can_create_project" in data
            assert not data['can_create_project']

        with patch('django.conf.settings.ONLY_SUPERUSER_CAN_CREATE_PROJECT', False):
            data = ext_make_auth_response_data(super_user)
            assert "can_create_project" in data
            assert data['can_create_project']

            data = ext_make_auth_response_data(user)
            assert "can_create_project" in data
            assert data['can_create_project']


class TestTimelineService:

    def test_build_project_namespace(self):
        from ...taiga_contrib_inps.timeline.services import build_project_namespace
        project = MagicMock()
        project.id = 1
        namespace = build_project_namespace(project)
        assert namespace == 'project:1'
