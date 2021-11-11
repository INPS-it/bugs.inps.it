###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.conf import settings
from taiga.base.api.permissions import IsAuthenticated
from taiga.base.fields import MethodField
from taiga.base.neighbors import NeighborsSerializerMixin
from taiga.projects.issues.serializers import IssueListSerializer, IssueSerializer
from taiga.users.serializers import UserAdminSerializer


class ExtIssueListSerializer(IssueListSerializer):
    is_public = MethodField()

    def get_is_public(self, obj):
        if hasattr(obj, 'issuevisibility'):
            return obj.issuevisibility.is_public
        else:
            return False


class ExtIssueSerializer(IssueSerializer):
    is_public = MethodField()

    def get_is_public(self, obj):
        if hasattr(obj, 'issuevisibility'):
            return obj.issuevisibility.is_public
        else:
            return False


class ExtIssueNeighborsSerializer(NeighborsSerializerMixin, ExtIssueSerializer):
    pass


class ExtUserAdminSerializer(UserAdminSerializer):
    can_create_project = MethodField()

    def get_can_create_project(self, user):
        can_create = user.is_superuser if getattr(
            settings, 'ONLY_SUPERUSER_CAN_CREATE_PROJECT', True) else IsAuthenticated()
        return can_create
