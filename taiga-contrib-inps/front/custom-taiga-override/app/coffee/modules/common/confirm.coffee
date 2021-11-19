###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos Ventures SL
###

taiga = @.taiga
timeout = @.taiga.timeout
cancelTimeout = @.taiga.cancelTimeout
debounce = @.taiga.debounce
bindMethods = @.taiga.bindMethods

NOTIFICATION_MSG = {
    "success":
        title: "NOTIFICATION.OK"
        message: "NOTIFICATION.SAVED"
    "error":
        title: "NOTIFICATION.WARNING"
        message: "NOTIFICATION.WARNING_TEXT"
    "light-error":
        title: "NOTIFICATION.WARNING"
        message: "NOTIFICATION.WARNING_TEXT"
}


class ConfirmService extends taiga.Service
    @.$inject = ["$q", "lightboxService", "$tgLoading", "$translate", "$filter"]

    constructor: (@q, @lightboxService, @loading, @translate, @filter) ->
        bindMethods(@)

    hide: (el)->
        if el
            @lightboxService.close(el)

            el.off(".confirm-dialog")

    ask: (title, subtitle, message, lightboxSelector=".lightbox-generic-ask") ->
        defered = @q.defer()

        el = angular.element(lightboxSelector)

        # Render content
        el.find(".title").text(title || '')
        el.find(".subtitle").text(subtitle || '')
        if message
            message = @filter('textToHTML')(message)
        el.find(".message").html(message || '')

        # Assign event handlers
        el.on "click.confirm-dialog", ".js-confirm", debounce 2000, (event) =>
            event.preventDefault()
            target = angular.element(event.currentTarget)
            currentWidth = target.width()
            target.width(currentWidth)
            currentLoading = @loading()
                .target(target)
                .start()
            defered.resolve {
                finish: (ok=true) =>
                    target.css("width", "");
                    currentLoading.finish()
                    if ok
                        @.hide(el)
            }

        el.on "click.confirm-dialog", ".js-cancel", (event) =>
            event.preventDefault()
            defered.reject()
            @.hide(el)

        onEsc = () =>
            @.hide(el)

        @lightboxService.open(el, null, onEsc)

        return defered.promise

    askDelete: (title, subtitle, message, lightboxSelector=".lightbox-generic-delete") ->
        defered = @q.defer()

        lightbox = angular.element(lightboxSelector)

        # Render content
        lightbox.find(".title").text(title || '')
        lightbox.find(".subtitle").text(subtitle || '')
        if message
            message = @filter('textToHTML')(message)
        lightbox.find(".message").html(message || '')

        # Assign event handlers
        lightbox.on "click.confirm-dialog", ".js-confirm", debounce 2000, (event) =>
            event.preventDefault()
            target = angular.element(event.currentTarget)
            currentWidth = target.width()
            target.width(currentWidth)
            currentLoading = @loading()
                .target(target)
                .start()
            defered.resolve {
                finish: (ok=true) =>
                    target.css("width", "");
                    currentLoading.finish()
                    if ok
                        @.hide(lightbox)
            }

        lightbox.on "click.confirm-dialog", ".js-cancel", (event) =>
            event.preventDefault()
            defered.reject()
            @.hide(lightbox)

        onEsc = () =>
            @.hide(lightbox)

        @lightboxService.open(lightbox, null, onEsc)

        return defered.promise

    askOnDelete: (title, message, subtitle) ->
        if not subtitle?
            subtitle = @translate.instant("NOTIFICATION.ASK_DELETE")
        return @.askDelete(title, subtitle, message)

    askChoice: (title, subtitle, choices, replacement, warning, lightboxSelector=".lightbox-ask-choice") ->
        defered = @q.defer()

        el = angular.element(lightboxSelector)

        # Render content
        el.find(".title").text(title)
        el.find(".subtitle").text(subtitle)

        if replacement
            el.find(".replacement").text(replacement)
        else
            el.find(".replacement").remove()

        if warning
            el.find(".warning").text(warning)
        else
            el.find(".warning").remove()

        choicesField = el.find(".choices")
        choicesField.html('')
        _.each choices, (value, key) ->
            value = _.escape(value)
            choicesField.append(angular.element("<option value='#{key}'>#{value}</option>"))

        # Assign event handlers
        el.on "click.confirm-dialog", ".js-confirm-ask", debounce 2000, (event) =>
            event.preventDefault()
            target = angular.element(event.currentTarget)
            currentLoading = @loading()
                .target(target)
                .start()
            defered.resolve {
                selected: choicesField.val()
                finish: (ok=true) =>
                    currentLoading.finish()
                    if ok
                        @.hide(el)
            }

        el.on "click.confirm-dialog", ".js-cancel-ask", (event) =>
            event.preventDefault()
            defered.reject()
            @.hide(el)

        @lightboxService.open(el)

        return defered.promise

    error: (message) ->
        defered = @q.defer()

        el = angular.element(".lightbox-generic-error")

        # Render content
        el.find(".title").html(message)

        # Assign event handlers
        el.on "click.confirm-dialog", ".button-green", (event) =>
            event.preventDefault()
            defered.resolve()
            @.hide(el)

        el.on "click.confirm-dialog", ".close", (event) =>
            event.preventDefault()
            defered.resolve()
            @.hide(el)

        @lightboxService.open(el)

        return defered.promise

    success: (title, message, icon, action) ->
        defered = @q.defer()

        el = angular.element(".lightbox-generic-success")

        el.find("img").remove()
        el.find("svg").remove()

        if icon
            if icon.type == "img"
                detailImage = $('<img>').addClass('lb-icon').attr('src', icon.name)
            else if icon.type == "svg"
                detailImage = document.createElement("div")
                taiga.addClass(detailImage, "icon")
                taiga.addClass(detailImage, icon.name)
                taiga.addClass(detailImage, "lb-icon")

                svgContainer = document.createElementNS("http://www.w3.org/2000/svg", "svg")

                useSVG = document.createElementNS('http://www.w3.org/2000/svg', 'use')
                useSVG.setAttributeNS('http://www.w3.org/1999/xlink','href', '#' + icon.name)

                detailImage.appendChild(svgContainer).appendChild(useSVG)

            if detailImage
                el.find('section').prepend(detailImage)

        # Render content
        el.find(".title").html(title) if title
        el.find(".message").html(message) if message
        if action
            el.find(".js-confirm").html(action)
            el.find(".js-confirm").attr('title', action)

        # Assign event handlers
        el.on "click.confirm-dialog", ".js-confirm", (event) =>
            event.preventDefault()
            defered.resolve()
            @.hide(el)

        el.on "click.confirm-dialog", ".close", (event) =>
            event.preventDefault()
            defered.resolve()
            @.hide(el)

        @lightboxService.open(el)

        return defered.promise

    loader: (title, message, spin=false) ->
        el = angular.element(".lightbox-generic-loading")

        # Render content
        el.find(".title").html(title) if title
        el.find(".message").html(message) if message

        if spin
            el.find(".spin").removeClass("hidden")

        return {
            start: => @lightboxService.open(el)
            stop: => @lightboxService.close(el)
            update: (status, title, message, percent) =>
                el.find(".title").html(title) if title
                el.find(".message").html(message) if message

                if percent
                    el.find(".spin").addClass("hidden")
                    el.find(".progress-bar-wrapper").removeClass("hidden")
                    el.find(".progress-bar-wrapper > .bar").width(percent + '%')
                    el.find(".progress-bar-wrapper > span").html(percent + '%').css('left', (percent - 9) + '%' )
                else
                    el.find(".spin").removeClass("hidden")
                    el.find(".progress-bar-wrapper").addClass("hidden")
        }

    notify: (type, message, title, time) ->
        # NOTE: Typesi are: error, success, light-error
        #       See partials/components/notification-message.jade)
        #       Add default texts to NOTIFICATION_MSG for new notification types

        selector = ".notification-message-#{type}"
        el = angular.element(selector)

        return if el.hasClass("active")

        if title
            el.find("span.warning").html(title)
        else
            el.find("span.warning").html(@translate.instant(NOTIFICATION_MSG[type].title))

        if message
            el.find("p").html(message)
        else
            el.find("p").html(@translate.instant(NOTIFICATION_MSG[type].message))

        body = angular.element("body")
        body.find(".notification-message .notification-light")
            .removeClass('active')
            .addClass('inactive')

        body.find(selector)
            .removeClass('inactive')
            .addClass('active')

        if @.tsem
            cancelTimeout(@.tsem)

        if !time
            time = if type == 'error' or type == 'light-error' then 3500 else 1500

        @.tsem = timeout time, =>
            body.find(selector)
                .removeClass('active')
                .addClass('inactive')
                .one 'animationend', () -> $(this).removeClass('inactive')

            delete @.tsem

        el.on "click", ".icon-close, .close", (event) =>
            body.find(selector)
                .removeClass('active')
                .addClass('inactive')


module = angular.module("taigaCommon")
module.service("$tgConfirm", ConfirmService)
