###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos Ventures SL
###

taiga = @.taiga
groupBy = @.taiga.groupBy


class ProjectsService extends taiga.Service
    @.$inject = ["tgResources", "$projectUrl"]

    constructor: (@rs, @projectUrl) ->

    create: (data) ->
        return @rs.projects.create(data)

    duplicate: (projectId, data) ->
        return @rs.projects.duplicate(projectId, data)

    getProjectBySlug: (projectSlug) ->
        return @rs.projects.getProjectBySlug(projectSlug)
            .then (project) =>
                return @._decorate(project)

    getProjectStats: (projectId) ->
        return @rs.projects.getProjectStats(projectId)

    getProjectsByUserId: (userId, paginate) ->
        return @rs.projects.getProjectsByUserId(userId, paginate)
            .then (projects) =>
                return projects.map @._decorate.bind(@)

    getListProjectsByUserId: (userId, paginate) ->
        return @rs.projects.getListProjectsByUserId(userId, paginate)
            .then (projects) =>
                return projects.map @._decorate.bind(@)

    _decorate: (project) ->
        url = @projectUrl.get(project.toJS())

        project = project.set("url", url)

        return project

    bulkUpdateProjectsOrder: (sortData) ->
        return @rs.projects.bulkUpdateOrder(sortData)

    bulkUpdateCustomProjectsOrder: (sortData) ->
        return @rs.projects.bulkUpdateCustomOrder(sortData)

    transferValidateToken: (projectId, token) ->
        return @rs.projects.transferValidateToken(projectId, token)

    transferAccept: (projectId, token, reason) ->
        return @rs.projects.transferAccept(projectId, token, reason)

    transferReject: (projectId, token, reason) ->
        return @rs.projects.transferReject(projectId, token, reason)


angular.module("taigaProjects").service("tgProjectsService", ProjectsService)
