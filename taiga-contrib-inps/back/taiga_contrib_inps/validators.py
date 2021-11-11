###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from taiga.users.validators import UserValidator
from taiga.base.api import serializers
from taiga.base.exceptions import ValidationError

from taiga.users.models import User


class ExtUserValidator(UserValidator):
    full_name = serializers.CharField(max_length=255)


class ExtAdminUserValidator(ExtUserValidator):
    class Meta:
        model = User
        # IMPORTANT: Maintain the UserSerializer Meta up to date
        # with this info (including here the email)
        fields = ("username", "full_name", "color", "bio", "lang",
                  "theme", "timezone", "is_active", "email", "read_new_terms")

    def validate_read_new_terms(self, attrs, source):
        value = attrs[source]
        if not value:
            raise ValidationError(
                _("Read new terms has to be true'"))

        return attrs
