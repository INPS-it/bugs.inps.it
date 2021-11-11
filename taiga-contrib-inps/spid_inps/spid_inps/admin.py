###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.contrib import admin
from .models import Person


@admin.register(Person)
class PersonAdmin(admin.ModelAdmin):
    list_display = ('user', 'tin', 'modified', 'created')
    search_fields = ('tin', 'user__full_name', 'user__email')
    raw_id_fields = ('user', )
    readonly_fields = ('issuer', 'tin')
