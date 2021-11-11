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

UserSettingsNavigationDirective = ->
    link = ($scope, $el, $attrs) ->
        section = $attrs.tgUserSettingsNavigation
        $el.find(".active").removeClass("active")
        $el.find("#usersettingsmenu-#{section}").addClass("active")
        $scope.showChangePassword = $scope.user && $scope.user.roles && $scope.user.roles.length
        $scope.$on "$destroy", ->
            $el.off()

    return {link:link}

module = angular.module("taigaUserSettings")
module.directive("tgUserSettingsNavigation", UserSettingsNavigationDirective)