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

HomeProjectListDirective = (currentUserService) ->
    link = (scope, el, attrs, ctrl) ->
        scope.vm = {}

        taiga.defineImmutableProperty(scope.vm, "projects", () -> currentUserService.projects.get("recents"))
        taiga.defineImmutableProperty(scope.vm, "user_can_create_project", () -> currentUserService.getUser()?.get("can_create_project"))

    directive = {
        templateUrl: "home/projects/home-project-list.html"
        scope: {}
        link: link
    }

    return directive

HomeProjectListDirective.$inject = [
    "tgCurrentUserService"
]

angular.module("taigaHome").directive("tgHomeProjectList", HomeProjectListDirective)
