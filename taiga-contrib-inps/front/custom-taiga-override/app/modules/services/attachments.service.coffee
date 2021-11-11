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

sizeFormat = @.taiga.sizeFormat

class AttachmentsService
    @.$inject = [
        "$tgConfirm",
        "$tgConfig",
        "$translate",
        "tgResources"
    ]

    constructor: (@confirm, @config, @translate, @rs) ->
        @.types = {
            epics: "epic",
            userstories: "us",
            userstory: "us",
            issues: "issue",
            tasks: "task",
            epic: "epic",
            us: "us"
            issue: "issue",
            task: "task",
            wiki: "wiki",
            wikipage: "wiki"
        }
        @.maxFileSize = @.getMaxFileSize()
        @.attachmentMimeTypes = @.getMimeTypes()

        if @.maxFileSize
            @.maxFileSizeFormated = sizeFormat(@.maxFileSize)

    sizeError: (file) ->
        message = @translate.instant("ATTACHMENT.ERROR_MAX_SIZE_EXCEEDED", {
            fileName: file.name,
            fileSize: sizeFormat(file.size),
            maxFileSize: @.maxFileSizeFormated
        })

        @confirm.notify("error", message)

    mimeTypeError: (file) ->
        message = @translate.instant("ATTACHMENT.ERROR_MIMETYPE_NOT_SUPPORTED", {
            fileType: file.type,
            supportedMimeTypes: @.attachmentMimeTypes.toString(),
        })
        @confirm.notify("error", message)

    validate: (file) ->
        if @.maxFileSize && file.size > @.maxFileSize
            @.sizeError(file)
            return false

        if @.attachmentMimeTypes and @.attachmentMimeTypes.length and file.type not in @.attachmentMimeTypes
            @.mimeTypeError(file)
            return false

        return true

    getMaxFileSize: () ->
        return @config.get("maxUploadFileSize", null)

    getMimeTypes: () ->
        return @config.get("attachmentMymeTypes", null)

    list: (type, objId, projectId) ->
        return @rs.attachments.list(type, objId, projectId).then (attachments) =>
            return attachments.sortBy (attachment) => attachment.get('order')

    get: (type, id) ->
        return @rs.attachments.get(@.types[type], id)

    delete: (type, id) ->
        return @rs.attachments.delete(type, id)

    saveError: (file, data) ->
        message = ""

        if file
            message = @translate.instant("ATTACHMENT.ERROR_UPLOAD_ATTACHMENT", {
                        fileName: file.name, errorMessage: data.data._error_message
                      })

        @confirm.notify("error", message)

    upload: (file, objId, projectId, type, from_comment = false) ->
        promise = @rs.attachments.create(type, projectId, objId, file, from_comment)

        promise.then null, @.saveError.bind(this, file)

        return promise

    bulkUpdateOrder: (objectId, type, afterAttachmentId, bulkAttachments) ->
        promise = @rs.attachments.bulkAttachments(objectId, type, afterAttachmentId, bulkAttachments)

        promise.then null, @.saveError.bind(this, null)

        return promise

    patch: (id, type, patch) ->
        promise = @rs.attachments.patch(type, id, patch)

        promise.then null, @.saveError.bind(this, null)

        return promise

angular.module("taigaCommon").service("tgAttachmentsService", AttachmentsService)
