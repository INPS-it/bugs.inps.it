###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos Ventures SL
###

taiga = @.taiga

generateHash = taiga.generateHash

resourceProvider = ($repo, $http, $urls, $storage, $q) ->
    service = {}
    hashSuffix = "issues-queryparams"
    hashSprintShowTags = "taskboard-issues"
    hashIssuesShowTags = "issues-list"

    service.get = (projectId, issueId) ->
        params = service.getQueryParams(projectId)
        params.project = projectId
        return $repo.queryOne("issues", issueId, params)

    service.getByRef = (projectId, ref) ->
        params = service.getQueryParams(projectId)
        params.project = projectId
        params.ref = ref
        return $repo.queryOne("issues", "by_ref", params)

    service.listInAllProjects = (filters) ->
        return $repo.queryMany("issues", filters)

    service.list = (projectId, filters, options) ->
        params = {project: projectId}
        params = _.extend({}, params, filters or {})
        service.storeQueryParams(projectId, params)
        return $repo.queryPaginated("issues", params, options)

    service.listInProject = (projectId, sprintId=null, params) ->
        params = _.merge(params, {project: projectId})
        params.milestone = sprintId if sprintId
        service.storeQueryParams(projectId, params)
        return $repo.queryMany("issues", params)

    service.bulkCreate = (projectId, milestoneId, data) ->
        url = $urls.resolve("bulk-create-issues")
        params = {project_id: projectId,  milestone_id: milestoneId, bulk_issues: data}
        return $http.post(url, params)

    service.upvote = (issueId) ->
        url = $urls.resolve("issue-upvote", issueId)
        return $http.post(url)

    service.downvote = (issueId) ->
        url = $urls.resolve("issue-downvote", issueId)
        return $http.post(url)

    service.watch = (issueId) ->
        url = $urls.resolve("issue-watch", issueId)
        return $http.post(url)

    service.unwatch = (issueId) ->
        url = $urls.resolve("issue-unwatch", issueId)
        return $http.post(url)

    service.stats = (projectId) ->
        return $repo.queryOneRaw("projects", "#{projectId}/issues_stats")

    service.filtersData = (params) ->
        return $repo.queryOneRaw("issues-filters", null, params)

    service.listValues = (projectId, type) ->
        params = {"project": projectId}
        service.storeQueryParams(projectId, params)
        return $repo.queryMany(type, params)

    service.createDefaultValues = (projectId, type) ->
        data = {"project_id": projectId}
        url = $urls.resolve("#{type}-create-default")
        return $http.post(url, data)

    service.storeQueryParams = (projectId, params) ->
        ns = "#{projectId}:#{hashSuffix}"
        hash = generateHash([projectId, ns])
        $storage.set(hash, params)

    service.getQueryParams = (projectId) ->
        ns = "#{projectId}:#{hashSuffix}"
        hash = generateHash([projectId, ns])
        return $storage.get(hash) or {}

    service.bulkUpdateMilestone = (projectId, milestoneId, data) ->
        url = $urls.resolve("bulk-update-issue-milestone")
        params = {project_id: projectId, milestone_id: milestoneId, bulk_issues: data}
        return $http.post(url, params)

    service.promoteToUserStory = (issueId, projectId) ->
        url = $urls.resolve("promote-issue-to-us", issueId)
        data = {project_id: projectId}
        return $http.post(url, data)

    # Persist display Tags on issues section

    service.storeIssuesShowTags = (projectId, params) ->
        ns = "#{projectId}:#{hashIssuesShowTags}"
        hash = generateHash([projectId, ns])
        $storage.set(hash, params)

    service.getIssuesShowTags = (projectId) ->
        ns = "#{projectId}:#{hashIssuesShowTags}"
        hash = generateHash([projectId, ns])
        return $storage.get(hash)

    # Persist display Tags on taskboard issues list

    service.storeSprintShowTags = (projectId, params) ->
        ns = "#{projectId}:#{hashSprintShowTags}"
        hash = generateHash([projectId, ns])
        $storage.set(hash, params)

    service.getSprintShowTags = (projectId) ->
        ns = "#{projectId}:#{hashSprintShowTags}"
        hash = generateHash([projectId, ns])
        return $storage.get(hash)

    service.moveIssueTo = (projectId, issueData) ->
        url = $urls.resolve("move-issue-to")
        params = {project_id: projectId, issue_data: issueData}
        return $http.post(url, params)

    return (instance) ->
        instance.issues = service


module = angular.module("taigaResources")
module.factory("$tgIssuesResourcesProvider", ["$tgRepo", "$tgHttp", "$tgUrls", "$tgStorage", "$q", resourceProvider])
