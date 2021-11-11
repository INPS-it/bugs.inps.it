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

NavigationBarDirective = (currentUserService, navigationBarService, locationService, navUrlsService, config, feedbackService, $windowService) ->
    link = (scope, el, attrs, ctrl) ->
        scope.vm = {}

        taiga.defineImmutableProperty(scope.vm, "projects", () -> currentUserService.projects.get("recents"))
        taiga.defineImmutableProperty(scope.vm, "isAuthenticated", () -> currentUserService.isAuthenticated())
        taiga.defineImmutableProperty(scope.vm, "isEnabledHeader", () -> navigationBarService.isEnabledHeader())

        scope.vm.publicRegisterEnabled = config.get("publicRegisterEnabled")
        scope.vm.customSupportUrl = config.get("supportUrl")
        scope.vm.isFeedbackEnabled = config.get("feedbackEnabled")
            
        loadUserPilot = () =>
            userPilotIframe = document.querySelector('#userpilot-resource-centre-frame')

            if userPilotIframe
                scope.$applyAsync () =>
                    userPilotIframeDocument = userPilotIframe.contentWindow.document.body
                    widget = userPilotIframeDocument.querySelector('#widget-title')

                    if widget
                        scope.vm.userPilotTitle = widget.innerText
                        clearInterval(userPilotInterval)

        attempts = 10

        if window.TAIGA_USER_PILOT_TOKEN
            scope.vm.userPilotTitle = 'Help center'
            scope.vm.userpilotEnabled = true

            userPilotInterval = setInterval () =>
                loadUserPilot()
                attempts--

                if !attempts
                    clearInterval(userPilotInterval)
            , 1000

        scope.vm.login = ->
            nextUrl = encodeURIComponent(locationService.url())
            locationService.url(navUrlsService.resolve("login"))
            locationService.search({next: nextUrl})

        scope.vm.sendFeedback = () ->
            feedbackService.sendFeedback()

        scope.vm.toLoginSpidUrl = () ->
            $windowService.location.href = config.get("loginSpidUrl")

        window._taigaSendFeedback = scope.vm.sendFeedback

        scope.$on "$routeChangeSuccess", () ->
            scope.vm.active = null
            path = locationService.path()

            switch path
                when "/"
                    scope.vm.active = 'dashboard'
                when "/discover"
                    scope.vm.active = 'discover'
                when "/notifications"
                    scope.vm.active = 'notifications'
                when "/projects/"
                    scope.vm.active = 'projects'
                else
                    if path.startsWith('/project')
                        scope.vm.active = 'project'

    directive = {
        templateUrl: "navigation-bar/navigation-bar.html"
        scope: {}
        link: link
    }

    return directive

NavigationBarDirective.$inject = [
    "tgCurrentUserService",
    "tgNavigationBarService",
    "$tgLocation",
    "$tgNavUrls",
    "$tgConfig",
    "tgFeedbackService",
    "$window"
]

angular.module("taigaNavigationBar").directive("tgNavigationBar", NavigationBarDirective)
