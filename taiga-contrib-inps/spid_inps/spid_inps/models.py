###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.db import models
from django.contrib.auth import get_user_model


class Person(models.Model):
    user = models.OneToOneField(
        get_user_model(),
        on_delete=models.CASCADE,
        primary_key=True,
    )
    tin = models.CharField(
        max_length=64, blank=False, null=False, unique=True,
        help_text="unique person identifier"
    )
    created = models.DateTimeField(auto_now_add=True, editable=False)
    modified = models.DateTimeField(auto_now=True, editable=False)
    issuer = models.CharField(max_length=256, blank=True, default='')

    class Meta:
        app_label = 'taiga_contrib_inps'

    def __str__(self):
        return f"{self.user.username} [{self.tin}]"
