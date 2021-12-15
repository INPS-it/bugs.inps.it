###
# license-start
# 
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# 
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos Ventures SL
###

class HelpHomeController
    @.$inject = [
        "$scope",
        "$rootScope",
        '$tgLocation',
        '$tgNavUrls',
        'tgAppMetaService',
        '$translate'
    ]

    constructor: (@rootscope, @scope, @location, @navUrls, @appMetaService, @translate) ->
        @scope.lang = @translate.preferredLanguage()
        title = @translate.instant("HELP.TITLE")
        description = @translate.instant("HELP.PAGE_DESCRIPTION")
        @appMetaService.setAll(title, description)

angular.module("inpsHelp").controller("HelpHome", HelpHomeController)
