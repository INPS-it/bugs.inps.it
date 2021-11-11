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

DropdownUserDirective = (authService, configService, locationService,
        navUrlsService, $rootScope) ->

    link = (scope, el, attrs, ctrl) ->
        scope.vm = {}
        scope.vm.isFeedbackEnabled = configService.get("feedbackEnabled")
        scope.vm.customSupportUrl = configService.get("supportUrl")
        taiga.defineImmutableProperty(scope.vm, "user", () -> authService.userData)

        scope.vm.logout = ->
            authService.logout()
            # locationService.url(navUrlsService.resolve("discover"))
            # locationService.search({})

        scope.vm.userSettingsPlugins = _.filter($rootScope.userSettingsPlugins, {userMenu: true})

        # Let's update user data upon profile update to reflect changed name or thumbnail on the dropdown
        $rootScope.$on "profile:updated", (event, userData) ->
            el.find('a.profile-link.full-name').text(userData.getAttrs().full_name_display);

    directive = {
        templateUrl: "navigation-bar/dropdown-user/dropdown-user.html"
        scope: {}
        link: link
    }

    return directive

DropdownUserDirective.$inject = [
    "$tgAuth",
    "$tgConfig",
    "$tgLocation",
    "$tgNavUrls",
    "$rootScope"
]

angular.module("taigaNavigationBar").directive("tgDropdownUser", DropdownUserDirective)
