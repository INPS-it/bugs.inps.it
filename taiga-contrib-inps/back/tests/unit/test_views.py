###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###
from types import SimpleNamespace
from unittest.mock import patch, MagicMock
from django.conf import settings

from tests.factories import UserFactory
from ...taiga_contrib_inps.views import ExchangeTokenView


class TestExchangeTokenView:

    def valid_request_mock(self):
        req = MagicMock()
        req.POST = dict({'partial_code': 'partial_code_test'})
        req.session = dict({'partial_code_test': 3600})
        req.user = UserFactory.build()
        return req

    def refresh_token_mock(self, user):
        d = {'access_token': 'test-value'}
        return SimpleNamespace(**d)

    def time_mock(self, time=0):
        return 0

    def test_without_partial_code(self):
        req = self.valid_request_mock()
        req.POST = dict({})
        res = ExchangeTokenView.post(
            ExchangeTokenView.as_view(), req, 'partial_code')
        assert res.status_code == 403

    def test_without_session(self):
        req = self.valid_request_mock()
        req.session = dict({})
        res = ExchangeTokenView.post(
            ExchangeTokenView.as_view(), req, 'partial_code')
        assert res.status_code == 403

    def test_with_expired_token(self):
        max_duration = getattr(settings, "TOKEN_CHALLENGE_MAX_DURATION", "20")
        with patch('time.time', self.time_mock(int(max_duration)+1)):
            req = self.valid_request_mock()
            req.session = dict({})
            res = ExchangeTokenView.post(
                ExchangeTokenView.as_view(), req, 'partial_code')
            assert res.status_code == 403

    def test_wit_partial_code(self):
        with patch('time.time', self.time_mock):
            with patch("taiga.auth.tokens.RefreshToken.for_user", self.refresh_token_mock):
                req = self.valid_request_mock()
                response = ExchangeTokenView.post(
                    ExchangeTokenView.as_view(), req, 'partial_code')
                assert response.status_code == 200
