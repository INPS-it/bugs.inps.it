###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.conf import settings
from taiga.base.api import serializers
from taiga.base.fields import Field, MethodField, I18NField
from taiga.base.api.permissions import IsAuthenticated
from taiga.base.fields import MethodField
from taiga.base.neighbors import NeighborsSerializerMixin
from taiga.projects.issues.serializers import IssueListSerializer, IssueSerializer
from taiga.users.serializers import UserAdminSerializer


class ExtIssueListSerializer(IssueListSerializer):
    is_public = MethodField()
    issue_url = MethodField()

    def get_is_public(self, obj):
        if hasattr(obj, 'issuevisibility'):
            return obj.issuevisibility.is_public
        else:
            return False

    def get_issue_url(self, obj):
        if hasattr(obj, 'issue_url'):
            return obj.issue_url.issue_url
        else:
            return False


class ExtIssueSerializer(IssueSerializer):
    is_public = MethodField()
    issue_url = MethodField()

    def get_is_public(self, obj):
        if hasattr(obj, 'issuevisibility'):
            return obj.issuevisibility.is_public
        else:
            return False

    def get_issue_url(self, obj):
        if hasattr(obj, 'issue_url'):
            return obj.issue_url.issue_url
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

class UserSerializer(serializers.LightSerializer):
    id = Field(attr="pk")
    permalink = MethodField()
    username = MethodField()
    full_name = MethodField()
    photo = MethodField()
    gravatar_id = MethodField()

    def get_permalink(self, obj):
        return resolve_front_url("user", obj.username)

    def get_username(self, obj):
        return obj.get_username()

    def get_full_name(self, obj):
        return obj.get_full_name()

    def get_photo(self, obj):
        return get_user_photo_url(obj)

    def get_gravatar_id(self, obj):
        return get_user_gravatar_id(obj)

    def to_value(self, instance):
        if instance is None:
            return None

        return super().to_value(instance)

class UserAdminSerializer(UserSerializer):
    total_private_projects = MethodField()
    total_public_projects = MethodField()
    email = Field()
    uuid = Field()
    date_joined = Field()
    read_new_terms = Field()
    accepted_terms = Field()
    max_private_projects = Field()
    max_public_projects = Field()
    max_memberships_private_projects = Field()
    max_memberships_public_projects = Field()
    verified_email = Field()

    def get_total_private_projects(self, user):
        return user.owned_projects.filter(is_private=True).count()

    def get_total_public_projects(self, user):
        return user.owned_projects.filter(is_private=False).count()
