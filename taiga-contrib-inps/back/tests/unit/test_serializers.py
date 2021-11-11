###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###
from unittest.mock import MagicMock

from tests.factories import UserFactory
from ...taiga_contrib_inps.serializers import ExtUserAdminSerializer, ExtIssueSerializer, ExtIssueListSerializer


class TestExtUserAdminSerializer:

    def test_model_serializer(self):
        user = UserFactory.build()
        serializer = ExtUserAdminSerializer(user)
        assert serializer.data
        assert "can_create_project" in serializer.data


class TestExtIssueSerializer:

    def issue_mock(self):
        issue = MagicMock()
        issue.owner = UserFactory.build()
        issue.assigned_to = UserFactory.build()
        return issue

    def test_issue_model_serializer(self):
        issue = self.issue_mock()

        issue.issuevisibility.is_public = False
        serializer = ExtIssueSerializer(issue)
        assert serializer.data
        assert "is_public" in serializer.data

        del issue.issuevisibility
        serializer = ExtIssueSerializer(issue)
        assert serializer.data
        assert "is_public" in serializer.data

    def test_issue_data_serialized(self):
        issue = self.issue_mock()

        issue.issuevisibility.is_public = True
        serializer = ExtIssueSerializer(issue)
        issue_data = serializer.data
        assert issue_data['is_public']

        issue.issuevisibility.is_public = False
        serializer = ExtIssueSerializer(issue)
        issue_data = serializer.data
        assert not issue_data['is_public']

        del issue.issuevisibility
        serializer = ExtIssueSerializer(issue)
        assert serializer.data
        assert not issue_data['is_public']

    def test_issue_list_model_serializer(self):
        issue = self.issue_mock()

        serializer = ExtIssueListSerializer(issue)
        assert serializer.data
        assert "is_public" in serializer.data

        del issue.issuevisibility
        serializer = ExtIssueListSerializer(issue)
        assert serializer.data
        assert "is_public" in serializer.data

    def test_issue_list_data_serialized(self):
        issue = self.issue_mock()

        issue.issuevisibility.is_public = True
        serializer = ExtIssueListSerializer(issue)
        issue_data = serializer.data
        assert issue_data['is_public']

        issue.issuevisibility.is_public = False
        serializer = ExtIssueListSerializer(issue)
        issue_data = serializer.data
        assert not issue_data['is_public']

        del issue.issuevisibility
        serializer = ExtIssueListSerializer(issue)
        assert serializer.data
        assert not issue_data['is_public']
