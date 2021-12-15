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

taiga = @.taiga

mixOf = @.taiga.mixOf

module = angular.module("taigaTeam")

#############################################################################
## Team Controller
#############################################################################

class TeamController extends mixOf(taiga.Controller, taiga.PageMixin)
    @.$inject = [
        "$scope",
        "$rootScope",
        "$tgRepo",
        "$tgResources",
        "$routeParams",
        "$q",
        "$location",
        "$tgNavUrls",
        "tgAppMetaService",
        "$tgAuth",
        "$translate",
        "tgProjectService",
        "tgErrorHandlingService"
    ]

    constructor: (@scope, @rootscope, @repo, @rs, @params, @q, @location, @navUrls, @appMetaService, @auth,
                  @translate, @projectService, @errorHandlingService) ->
        @scope.sectionName = "TEAM.SECTION_NAME"

        promise = @.loadInitialData()

        # On Success
        promise.then =>
            title = @translate.instant("TEAM.PAGE_TITLE", {projectName: @scope.project.name})
            description = @translate.instant("TEAM.PAGE_DESCRIPTION", {
                projectName: @scope.project.name,
                projectDescription: @scope.project.description
            })
            @appMetaService.setAll(title, description)

        # On Error
        promise.then null, @.onInitialDataError.bind(@)

    setRole: (role) ->
        if role
            @scope.filtersRole = role
        else
            @scope.filtersRole = null

    loadMembers: ->
        user = @auth.getUser()

        # Calculate totals
        @scope.totals = {}
        for member in @scope.activeUsers
            @scope.totals[member.id] = 0

        # Get current user
        @scope.currentUser = _.find(@scope.activeUsers, {id: user?.id})

        # Get member list without current user
        # Commented out because we need users email for admin to be displayed in the members table
        # @scope.memberships = _.reject(@scope.activeUsers, {id: user?.id})

        # Get member list from membership resource service (admin get also user emails)
        # Backend will take care of securing this API
        @rs.memberships.list(@scope.projectId).then (data) =>

            @scope.memberships = _.filter(
                data.models, (membership) ->
                                    membership.is_owner == false and membership.is_user_active == true and membership.user != null
                )

            @scope.memberships = _.map(
                @scope.memberships, (membership) -> 
                    return membership.getAttrs()
                )

    loadProject: ->
        project = @projectService.project.toJS()

        @scope.projectId = project.id
        @scope.project = project
        @scope.$emit('project:loaded', project)

        @scope.issuesEnabled = project.is_issues_activated
        @scope.tasksEnabled = project.is_kanban_activated or project.is_backlog_activated
        @scope.wikiEnabled = project.is_wiki_activated
        @scope.owner = project.owner.id

        return project

    loadMemberStats: ->
        return @rs.projects.memberStats(@scope.projectId).then (stats) =>
          totals = {}
          _.forEach @scope.totals, (total, userId) =>
              vals = _.map(stats, (memberStats, statsKey) -> memberStats[userId])
              total = _.reduce(vals, (sum, el) -> sum + el)
              @scope.totals[userId] = total

          @scope.stats = @._processStats(stats)
          @scope.stats.totals = @scope.totals

    _processStat: (stat) ->
        max = _.max(_.toArray(stat))
        min = _.min(_.toArray(stat))

        singleStat = Object()
        for own key, value of stat
            if value == min
                singleStat[key] = 0.1
            else if value == max
                singleStat[key] = 1
            else
                singleStat[key] = (value * 0.5) / max

        return singleStat

    _processStats: (stats) ->
        for key,value of stats
            stats[key] = @._processStat(value)
        return stats

    loadInitialData: ->
        project = @.loadProject()

        @.fillUsersAndRoles(project.members, project.roles)
        @.loadMembers()

        userRoles = _.map @scope.users, (user) -> user.role

        @scope.roles = _.filter @scope.roles, (role) -> userRoles.indexOf(role.id) != -1

        return @.loadMemberStats()

module.controller("TeamController", TeamController)


#############################################################################
## Team Filters Directive
#############################################################################

TeamFiltersDirective = () ->
    return {
        templateUrl: "team/team-filter.html"
    }

module.directive("tgTeamFilters", [TeamFiltersDirective])


#############################################################################
## Team Member Stats Directive
#############################################################################

TeamMemberStatsDirective = () ->
    return {
        templateUrl: "team/team-member-stats.html",
        scope: {
            stats: "=",
            userId: "=user"
            issuesEnabled: "=issuesenabled"
            tasksEnabled: "=tasksenabled"
            wikiEnabled: "=wikienabled"
        }
    }

module.directive("tgTeamMemberStats", TeamMemberStatsDirective)


#############################################################################
## Team Current User Directive
#############################################################################

TeamMemberCurrentUserDirective = () ->
    return {
        templateUrl: "team/team-member-current-user.html"
        scope: {
            project: "=project",
            currentUser: "=currentuser",
            stats: "=",
            issuesEnabled: "=issuesenabled",
            tasksEnabled: "=tasksenabled",
            wikiEnabled: "=wikienabled",
            owner: "=owner"
        }
    }

module.directive("tgTeamCurrentUser", TeamMemberCurrentUserDirective)


#############################################################################
## Team Members Directive
#############################################################################

TeamMembersDirective = () ->
    template = "team/team-members.html"

    return {
        templateUrl: template
        scope: {
            memberships: "=",
            filtersQ: "=filtersq",
            filtersRole: "=filtersrole",
            stats: "=",
            issuesEnabled: "=issuesenabled",
            tasksEnabled: "=tasksenabled",
            wikiEnabled: "=wikienabled",
            owner: "=owner"
        }
    }

module.directive("tgTeamMembers", TeamMembersDirective)


#############################################################################
## Leave project Directive
#############################################################################

LeaveProjectDirective = ($repo, $confirm, $location, $rs, $navurls, $translate, lightboxFactory, currentUserService) ->
    link = ($scope, $el, $attrs) ->
        leaveConfirm = () ->
            leave_project_text = $translate.instant("TEAM.ACTION_LEAVE_PROJECT")
            confirm_leave_project_text = $translate.instant("TEAM.CONFIRM_LEAVE_PROJECT")

            $confirm.ask(leave_project_text, confirm_leave_project_text).then (response) =>
                promise = $rs.projects.leave($scope.project.id)

                promise.then =>
                    currentUserService.loadProjects().then () ->
                        response.finish()
                        $confirm.notify("success")
                        $location.path($navurls.resolve("home"))

                promise.then null, (response) ->
                    response.finish()
                    $confirm.notify('error', response.data._error_message)

        $scope.leave = () ->
            if $scope.project.owner.id == $scope.user.id
                lightboxFactory.create("tg-lightbox-leave-project-warning", {
                    class: "lightbox lightbox-leave-project-warning"
                }, {
                    isCurrentUser: true,
                    project: $scope.project
                })
            else
                leaveConfirm()

    return {
        scope: {
            user: "=",
            project: "="
        },
        templateUrl: "team/leave-project.html",
        link: link
    }

module.directive("tgLeaveProject", ["$tgRepo", "$tgConfirm", "$tgLocation", "$tgResources", "$tgNavUrls", "$translate", "tgLightboxFactory", "tgCurrentUserService",
                                    LeaveProjectDirective])


#############################################################################
## Team Filters
#############################################################################

membersFilter = ->
    return (members, filtersQ, filtersRole) ->
        return _.filter members, (m) -> (not filtersRole or m.role == filtersRole.id) and
                                        (not filtersQ or m.full_name.search(new RegExp(filtersQ, "i")) >= 0)

module.filter('membersFilter', membersFilter)
