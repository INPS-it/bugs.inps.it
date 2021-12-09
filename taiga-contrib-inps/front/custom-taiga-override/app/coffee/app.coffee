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

@taiga = taiga = {}
taiga.emojis = window.emojis
@.taigaContribPlugins = @.taigaContribPlugins or window.taigaContribPlugins or []

# Generic function for generate hash from a arbitrary length
# collection of parameters.
taiga.generateHash = (components=[]) ->
    components = _.map(components, (x) -> JSON.stringify(x))
    return hex_sha1(components.join(":"))


taiga.generateUniqueSessionIdentifier = ->
    date = (new Date()).getTime()
    randomNumber = Math.floor(Math.random() * 0x9000000)
    return taiga.generateHash([date, randomNumber])


taiga.sessionId = taiga.generateUniqueSessionIdentifier()


configure = ($routeProvider, $locationProvider, $httpProvider, $provide, $tgEventsProvider, $compileProvider,
             $translateProvider, $translatePartialLoaderProvider, $animateProvider, $logProvider) ->

    $animateProvider.classNameFilter(/^(?:(?!ng-animate-disabled).)*$/)

    # wait until the translation is ready to resolve the page
    originalWhen = $routeProvider.when

    $routeProvider.when = (path, route) ->
        route.resolve || (route.resolve = {})
        angular.extend(route.resolve, {
            languageLoad: ["$q", "$translate", ($q, $translate) ->
                deferred = $q.defer()

                $translate("COMMON.YES").then () -> deferred.resolve()

                return deferred.promise
            ],
            projectLoaded: ["$q", "tgProjectService", "$route", ($q, projectService, $route) ->
                deferred = $q.defer()

                projectService.setSection($route.current.$$route?.section)

                if $route.current.params.pslug
                    projectService.setProjectBySlug($route.current.params.pslug).then(deferred.resolve)
                else
                    projectService.cleanProject()
                    deferred.resolve()

                return deferred.promise
            ]
        })

        return originalWhen.call($routeProvider, path, route)

    # Home
    $routeProvider.when("/",
        {
            templateUrl: "home/home.html",
            controller: "Home",
            controllerAs: "vm"
            loader: true,
            title: "HOME.PAGE_TITLE",
            loader: true,
            description: "HOME.PAGE_DESCRIPTION",
            joyride: "dashboard"
        }
    )

    # Discover
    $routeProvider.when("/discover",
        {
            templateUrl: "discover/discover-home/discover-home.html",
            controller: "DiscoverHome",
            controllerAs: "vm",
            title: "PROJECT.NAVIGATION.DISCOVER",
            loader: true
        }
    )

    $routeProvider.when("/discover/search",
        {
            templateUrl: "discover/discover-search/discover-search.html",
            title: "PROJECT.NAVIGATION.DISCOVER",
            loader: true,
            controller: "DiscoverSearch",
            controllerAs: "vm",
            reloadOnSearch: false
        }
    )

    # My Projects
    $routeProvider.when("/projects/",
        {
            templateUrl: "projects/listing/projects-listing.html",
            access: {
                requiresLogin: true
            },
            title: "PROJECTS.PAGE_TITLE",
            description: "PROJECTS.PAGE_DESCRIPTION",
            loader: true,
            controller: "ProjectsListing",
            controllerAs: "vm"
        }
    )

    # Project
    $routeProvider.when("/project/new",
        {
            title: "PROJECT.CREATE.TITLE",
            templateUrl: "projects/create/create-project.html",
            loader: true,
            controller: "CreateProjectCtrl",
            controllerAs: "vm"
        }
    )

    # Project - scrum
    $routeProvider.when("/project/new/scrum",
        {
            title: "PROJECT.CREATE.TITLE",
            template: "<tg-create-project-form type=\"scrum\"></tg-create-project-form>",
            loader: true
        }
    )

    # Project - kanban
    $routeProvider.when("/project/new/kanban",
        {
            title: "PROJECT.CREATE.TITLE",
            template: "<tg-create-project-form type=\"kanban\"></tg-create-project-form>",
            loader: true
        }
    )

    # Project - duplicate
    $routeProvider.when("/project/new/duplicate",
        {
            title: "PROJECT.CREATE.TITLE",
            template: "<tg-duplicate-project></tg-duplicate-project>",
            loader: true
        }
    )

    # Project - import
    $routeProvider.when("/project/new/import/:platform?",
        {
            title: "PROJECT.CREATE.TITLE",
            template: "<tg-import-project></tg-import-project>",
            loader: true
        }
    )

    # Project
    $routeProvider.when("/project/:pslug/",
        {
            template: "",
            loader: true,
            controller: "ProjectRouter"
        }
    )

    # Project
    $routeProvider.when("/project/:pslug/timeline",
        {
            templateUrl: "projects/project/project.html",
            loader: true,
            controller: "Project",
            controllerAs: "vm"
            section: "project-timeline"
        }
    )

    # Project ref detail
    $routeProvider.when("/project/:pslug/t/:ref",
        {
            loader: true,
            controller: "DetailController",
            template: ""
        }
    )

    $routeProvider.when("/project/:pslug/search",
        {
            templateUrl: "search/search.html",
            reloadOnSearch: false,
            section: "search",
            loader: true
        }
    )

    # Epics
    $routeProvider.when("/project/:pslug/epics",
        {
            section: "epics",
            templateUrl: "epics/dashboard/epics-dashboard.html",
            loader: true,
            controller: "EpicsDashboardCtrl",
            controllerAs: "vm"
        }
    )

    $routeProvider.when("/project/:pslug/epic/:epicref",
        {
            templateUrl: "epic/epic-detail.html",
            loader: true,
            section: "epics"
        }
    )

    $routeProvider.when("/project/:pslug/backlog",
        {
            templateUrl: "backlog/backlog.html",
            loader: true,
            section: "backlog",
            joyride: "backlog"
        }
    )

    $routeProvider.when("/project/:pslug/kanban",
        {
            templateUrl: "kanban/kanban.html",
            loader: true,
            section: "kanban",
            joyride: "kanban"
        }
    )

    # Milestone
    $routeProvider.when("/project/:pslug/taskboard/:sslug",
        {
            templateUrl: "taskboard/taskboard.html",
            loader: true,
            section: "backlog"
        }
    )

    # User stories
    $routeProvider.when("/project/:pslug/us/:usref",
        {
            templateUrl: "us/us-detail.html",
            loader: true,
            section: "backlog-kanban"
        }
    )

    # Tasks
    $routeProvider.when("/project/:pslug/task/:taskref",
        {
            templateUrl: "task/task-detail.html",
            loader: true,
            section: "backlog-kanban"
        }
    )

    # Wiki
    $routeProvider.when("/project/:pslug/wiki",
        {redirectTo: (params) -> "/project/#{params.pslug}/wiki/home"}, )
    $routeProvider.when("/project/:pslug/wiki-list",
        {
            templateUrl: "wiki/wiki-list.html",
            loader: true,
            section: "wiki"
        }
    )
    $routeProvider.when("/project/:pslug/wiki/:slug",
        {
            templateUrl: "wiki/wiki.html",
            loader: true,
            section: "wiki"
        }
    )

    # Team
    $routeProvider.when("/project/:pslug/team",
        {
            templateUrl: "team/team.html",
            loader: true,
            section: "team"
        }
    )

    # Issues
    $routeProvider.when("/project/:pslug/issues",
        {
            templateUrl: "issue/issues.html",
            loader: true,
            section: "issues"
        }
    )
    $routeProvider.when("/project/:pslug/issue/:issueref",
        {
            templateUrl: "issue/issues-detail.html",
            loader: true,
            section: "issues"
        }
    )

    # Admin - Project Profile
    $routeProvider.when("/project/:pslug/admin/project-profile/details",
        {
            templateUrl: "admin/admin-project-profile.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-profile/default-values",
        {
            templateUrl: "admin/admin-project-default-values.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-profile/modules",
        {
            templateUrl: "admin/admin-project-modules.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-profile/export",
        {
            templateUrl: "admin/admin-project-export.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-profile/reports",
        {
            templateUrl: "admin/admin-project-reports.html",
            section: "admin"
        }
    )

    $routeProvider.when("/project/:pslug/admin/project-values/status",
        {
            templateUrl: "admin/admin-project-values-status.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/points",
        {
            templateUrl: "admin/admin-project-values-points.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/priorities",
        {
            templateUrl: "admin/admin-project-values-priorities.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/severities",
        {
            templateUrl: "admin/admin-project-values-severities.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/types",
        {
            templateUrl: "admin/admin-project-values-types.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/custom-fields",
        {
            templateUrl: "admin/admin-project-values-custom-fields.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/tags",
        {
            templateUrl: "admin/admin-project-values-tags.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/due-dates",
        {
            templateUrl: "admin/admin-project-values-due-dates.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/project-values/kanban-power-ups",
        {
            templateUrl: "admin/admin-project-values-kanban-power-ups.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/memberships",
        {
            templateUrl: "admin/admin-memberships.html",
            section: "admin"
        }
    )
    # Admin - Roles
    $routeProvider.when("/project/:pslug/admin/roles",
        {
            templateUrl: "admin/admin-roles.html",
            section: "admin"
        }
    )

    # Admin - Third Parties
    $routeProvider.when("/project/:pslug/admin/third-parties/webhooks",
        {
            templateUrl: "admin/admin-third-parties-webhooks.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/third-parties/github",
        {
            templateUrl: "admin/admin-third-parties-github.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/third-parties/gitlab",
        {
            templateUrl: "admin/admin-third-parties-gitlab.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/third-parties/bitbucket",
        {
            templateUrl: "admin/admin-third-parties-bitbucket.html",
            section: "admin"
        }
    )
    $routeProvider.when("/project/:pslug/admin/third-parties/gogs",
        {
            templateUrl: "admin/admin-third-parties-gogs.html",
            section: "admin"
        }
    )
    # Admin - Contrib Plugins
    $routeProvider.when("/project/:pslug/admin/contrib/:plugin",
        {templateUrl: "contrib/main.html"})

    # Transfer project
    $routeProvider.when("/project/:pslug/transfer/:token",
        {
            templateUrl: "projects/transfer/transfer-page.html",
            loader: true,
            controller: "Project",
            controllerAs: "vm"
        }
    )

    # User settings
    $routeProvider.when("/user-settings/user-profile",
        {templateUrl: "user/user-profile.html"})
    $routeProvider.when("/user-settings/user-change-password",
        {templateUrl: "user/user-change-password.html"})
    $routeProvider.when("/user-settings/user-project-settings",
        {templateUrl: "user/user-project-settings.html"})
    $routeProvider.when("/user-settings/mail-notifications",
        {templateUrl: "user/mail-notifications.html"})
    $routeProvider.when("/user-settings/live-notifications",
        {templateUrl: "user/live-notifications.html"})
    $routeProvider.when("/user-settings/web-notifications",
        {templateUrl: "user/web-notifications.html"})
    $routeProvider.when("/change-email/:email_token",
        {templateUrl: "user/change-email.html"})
    $routeProvider.when("/verify-email/:email_token",
        {templateUrl: "user/verify-email.html"})
    $routeProvider.when("/cancel-account/:cancel_token",
        {templateUrl: "user/cancel-account.html"})

    # UserSettings - Contrib Plugins
    $routeProvider.when("/user-settings/contrib/:plugin",
        {templateUrl: "contrib/user-settings.html"})

    # User profile
    $routeProvider.when("/profile",
        {
            templateUrl: "profile/profile.html",
            loader: true,
            access: {
                requiresLogin: true
            },
            controller: "Profile",
            controllerAs: "vm"
        }
    )

    # Notifications
    $routeProvider.when("/notifications",
        {
            templateUrl: "notifications/notifications.html",
            loader: true,
            access: {
                requiresLogin: true
            },
            controller: "Notifications",
            controllerAs: "vm"
        }
    )

    $routeProvider.when("/profile/:slug",
        {
            templateUrl: "profile/profile.html",
            loader: true,
            controller: "Profile",
            controllerAs: "vm"
        }
    )

    # Auth
    $routeProvider.when("/login",
        {
            templateUrl: "auth/login.html",
            title: "LOGIN.PAGE_TITLE",
            description: "LOGIN.PAGE_DESCRIPTION",
            disableHeader: true,
            controller: "LoginPage",
        }
    )
    $routeProvider.when("/post_login",
        {   
            templateUrl: "auth/post-login.html"
        }
    )
    if window.taigaConfig.publicRegisterEnabled
        $routeProvider.when("/register",
            {
                templateUrl: "auth/register.html",
                title: "REGISTER.PAGE_TITLE",
                description: "REGISTER.PAGE_DESCRIPTION",
                disableHeader: true
            }
        )
    $routeProvider.when("/forgot-password",
        {
            templateUrl: "auth/forgot-password.html",
            title: "FORGOT_PASSWORD.PAGE_TITLE",
            description: "FORGOT_PASSWORD.PAGE_DESCRIPTION",
            disableHeader: true
        }
    )
    $routeProvider.when("/change-password/:token",
        {
            templateUrl: "auth/change-password-from-recovery.html",
            title: "CHANGE_PASSWORD.PAGE_TITLE",
            description: "CHANGE_PASSWORD.PAGE_TITLE",
            disableHeader: true
        }
    )
    $routeProvider.when("/invitation/:token",
        {
            templateUrl: "auth/invitation.html",
            title: "INVITATION.PAGE_TITLE",
            description: "INVITATION.PAGE_DESCRIPTION",
            disableHeader: true
        }
    )
    $routeProvider.when("/external-apps",
        {
            templateUrl: "external-apps/external-app.html",
            title: "EXTERNAL_APP.PAGE_TITLE",
            description: "EXTERNAL_APP.PAGE_DESCRIPTION",
            controller: "ExternalApp",
            controllerAs: "vm",
            disableHeader: true,
            mobileViewport: true
        }
    )

    # Errors/Exceptions
    $routeProvider.when("/blocked-project/:pslug/",
        {
            templateUrl: "projects/project/blocked-project.html",
            loader: true,
        }
    )
    $routeProvider.when("/error",
        {templateUrl: "error/error.html"})
    $routeProvider.when("/not-found",
        {templateUrl: "error/not-found.html"})
    $routeProvider.when("/permission-denied",
        {templateUrl: "error/permission-denied.html"})

    $routeProvider.otherwise({templateUrl: "error/not-found.html"})
    $locationProvider.html5Mode({enabled: true, requireBase: false})

    defaultHeaders = {
        "Content-Type": "application/json"
        "Accept-Language": window.taigaConfig.defaultLanguage || "en"
        "X-Session-Id": taiga.sessionId
    }

    $httpProvider.defaults.headers.delete = defaultHeaders
    $httpProvider.defaults.headers.patch = defaultHeaders
    $httpProvider.defaults.headers.post = defaultHeaders
    $httpProvider.defaults.headers.put = defaultHeaders
    $httpProvider.defaults.headers.get = {
        "X-Session-Id": taiga.sessionId
    }

    $httpProvider.useApplyAsync(true)

    $tgEventsProvider.setSessionId(taiga.sessionId)

    # Add next param when user try to access to a secction need auth permissions.
    authHttpIntercept = ($q, $location, $navUrls, $lightboxService, errorHandlingService) ->
        httpResponseError = (response) ->
            if response.status == 0 || (response.status == -1 && !response.config.cancelable)
                $lightboxService.closeAll()

                errorHandlingService.error()
            else if response.status == 401 and $location.url().indexOf('/login') == -1
                # Let's display an informative 401 page
                $location.url($navUrls.resolve("unauthorized"))

                # nextUrl = $location.url()
                # search = $location.search()

                # if search.force_next
                #     $location.url($navUrls.resolve("login"))
                #         .search("force_next", search.force_next)
                # else
                #     $location.url($navUrls.resolve("login"))
                #         .search({
                #             "unauthorized": true
                #             "next": nextUrl
                #         })

            return $q.reject(response)

        return {
            responseError: httpResponseError
        }

    $provide.factory("authHttpIntercept", ["$q", "$location", "$tgNavUrls", "lightboxService",
                                           "tgErrorHandlingService", authHttpIntercept])

    $httpProvider.interceptors.push("authHttpIntercept")


    loaderIntercept = ($q, loaderService) ->
        return {
            request: (config) ->
                loaderService.logRequest()

                return config

            requestError: (rejection) ->
                loaderService.logResponse()

                return $q.reject(rejection)

            responseError: (rejection) ->
                loaderService.logResponse()

                return $q.reject(rejection)

            response: (response) ->
                loaderService.logResponse()

                return response
        }


    $provide.factory("loaderIntercept", ["$q", "tgLoader", loaderIntercept])

    $httpProvider.interceptors.push("loaderIntercept")

    # If there is an error in the version throw a notify error.
    # IMPROVEiMENT: Move this version error handler to USs, issues and tasks repository
    versionCheckHttpIntercept = ($q) ->
        httpResponseError = (response) ->
            if response.status == 400 && response.data.version
                # HACK: to prevent circular dependencies with [$tgConfirm, $translate]
                $injector = angular.element("body").injector()
                $injector.invoke(["$tgConfirm", "$translate", ($confirm, $translate) =>
                    versionErrorMsg = $translate.instant("ERROR.VERSION_ERROR")
                    $confirm.notify("error", versionErrorMsg, null, 10000)
                ])

            return $q.reject(response)

        return {responseError: httpResponseError}

    $provide.factory("versionCheckHttpIntercept", ["$q", versionCheckHttpIntercept])

    $httpProvider.interceptors.push("versionCheckHttpIntercept")


    blockingIntercept = ($q, errorHandlingService) ->
        # API calls can return blocked elements and in that situation the user will be redirected
        # to the blocked project page
        # This can happens in two scenarios
        # - An ok response containing a blocked_code in the data
        # - An error reponse when updating/creating/deleting including a 451 error code
        redirectToBlockedPage = ->
            errorHandlingService.block()

        responseOk = (response) ->
            if response.data.blocked_code
                redirectToBlockedPage()

            return response

        responseError = (response) ->
            if response.status == 451
                redirectToBlockedPage()

            return $q.reject(response)

        return {
            response: responseOk
            responseError: responseError
        }

    $provide.factory("blockingIntercept", ["$q", "tgErrorHandlingService", blockingIntercept])

    $httpProvider.interceptors.push("blockingIntercept")


    $compileProvider.debugInfoEnabled(window.taigaConfig.debugInfo || false)

    if localStorage.userInfo
        userInfo = JSON.parse(localStorage.userInfo)

    # i18n
    preferedLangCode = userInfo?.lang || window.taigaConfig.defaultLanguage || "en"

    $translatePartialLoaderProvider.addPart('taiga')
    $translateProvider
        .useLoader('$translatePartialLoader', {
            urlTemplate: '/' + window._version + '/locales/{part}/locale-{lang}.json'
        })
        .useSanitizeValueStrategy('escapeParameters')
        .addInterpolation('$translateMessageFormatInterpolation')
        .preferredLanguage(preferedLangCode)
        .useMissingTranslationHandlerLog()

    $translateProvider.fallbackLanguage("en")

    # decoratos plugins
    decorators = window.getDecorators()

    _.each decorators, (decorator) ->
        $provide.decorator decorator.provider, decorator.decorator

    # Enable or disable debug log messages
    $logProvider.debugEnabled(window.taigaConfig.debug)
    if window.taigaConfig.debug
        console.info("Debug mode is enable")

    ## debug-events
    ##
    ## NOTE: This code is useful to debug Angular events, overwrite $rootScope methos
    ##       $broadcast and $emit to log info in the browser console. Uncomment this for
    ##       debug purpose.
    ##
    # $provide.decorator '$rootScope', ($delegate) ->
    #     ignore_events = [
    #         "$routeChangeStart",
    #         "$routeChangeSuccess",
    #         "$locationChangeStart",
    #         "$locationChangeSuccess",
    #         "$translateChangeStart",
    #         "$translateChangeEnd",
    #         "$translateChangeSuccess",
    #         "$translateLoadingStart",
    #         "$translateLoadingEnd",
    #         "$translateLoadingSuccess",
    #         "$viewContentLoaded",
    #         "$destroy",
    #     ]
    #     Scope = $delegate.constructor
    #     origBroadcast = Scope.prototype.$broadcast
    #     origEmit = Scope.prototype.$emit
    #     Scope.prototype.$broadcast = ($scope) ->
    #         if arguments[0] not in ignore_events
    #             console.log(">> $BROADCAST:", arguments[0], arguments)
    #         return origBroadcast.apply(this, arguments)
    #     Scope.prototype.$emit = ($scope) ->
    #         if arguments[0] not in ignore_events
    #             console.log(">> $EMIT:", arguments[0], arguments)
    #         return origEmit.apply(this, arguments)
    #     return $delegate
    ## end debug-events

i18nInit = (lang, $translate) ->
    # i18n - moment.js
    moment.locale(lang)
    document.querySelector('html').setAttribute('lang', lang)

    if (lang != 'en') # en is the default, the file doesn't exist
        ljs.load "/#{window._version}/locales/moment-locales/" + lang + ".js"

    # i18n - checksley.js
    messages = {
        defaultMessage: $translate.instant("COMMON.FORM_ERRORS.DEFAULT_MESSAGE")
        type: {
            email: $translate.instant("COMMON.FORM_ERRORS.TYPE_EMAIL")
            url: $translate.instant("COMMON.FORM_ERRORS.TYPE_URL")
            urlstrict: $translate.instant("COMMON.FORM_ERRORS.TYPE_URLSTRICT")
            number: $translate.instant("COMMON.FORM_ERRORS.TYPE_NUMBER")
            digits: $translate.instant("COMMON.FORM_ERRORS.TYPE_DIGITS")
            dateIso: $translate.instant("COMMON.FORM_ERRORS.TYPE_DATEISO")
            alphanum: $translate.instant("COMMON.FORM_ERRORS.TYPE_ALPHANUM")
            phone: $translate.instant("COMMON.FORM_ERRORS.TYPE_PHONE")
        }
        notnull: $translate.instant("COMMON.FORM_ERRORS.NOTNULL")
        notblank: $translate.instant("COMMON.FORM_ERRORS.NOT_BLANK")
        required: $translate.instant("COMMON.FORM_ERRORS.REQUIRED")
        regexp: $translate.instant("COMMON.FORM_ERRORS.REGEXP")
        min: $translate.instant("COMMON.FORM_ERRORS.MIN")
        max: $translate.instant("COMMON.FORM_ERRORS.MAX")
        range: $translate.instant("COMMON.FORM_ERRORS.RANGE")
        minlength: $translate.instant("COMMON.FORM_ERRORS.MIN_LENGTH")
        maxlength: $translate.instant("COMMON.FORM_ERRORS.MAX_LENGTH")
        rangelength: $translate.instant("COMMON.FORM_ERRORS.RANGE_LENGTH")
        mincheck: $translate.instant("COMMON.FORM_ERRORS.MIN_CHECK")
        maxcheck: $translate.instant("COMMON.FORM_ERRORS.MAX_CHECK")
        rangecheck: $translate.instant("COMMON.FORM_ERRORS.RANGE_CHECK")
        equalto: $translate.instant("COMMON.FORM_ERRORS.EQUAL_TO")
        linewidth: $translate.instant("COMMON.FORM_ERRORS.LINEWIDTH") # Extra validator
        pikaday: $translate.instant("COMMON.FORM_ERRORS.PIKADAY") # Extra validator
    }
    checksley.updateMessages('default', messages)


init = ($log, $rootscope, $auth, $events, $analytics, $tagManager, $userPilot, $translate, $location, $navUrls, appMetaService,
        loaderService, navigationBarService, errorHandlingService, lightboxService, $tgConfig,
        projectService) ->
    $log.debug("Initialize application")

    $rootscope.$on '$translatePartialLoaderStructureChanged', () ->
        $translate.refresh()

    # Checksley - Extra validators
    validators = {
        linewidth: (val, width) ->
            lines = taiga.nl2br(val).split("<br />")

            valid = _.every lines, (line) ->
                line.length < width

            return valid
        pikaday: (val) ->
            prettyDate = $translate.instant("COMMON.PICKERDATE.FORMAT")
            return moment(val, prettyDate).isValid()
        url: (val) ->
            re_weburl = new RegExp(
                "^" +
                    # protocol identifier
                    "(?:(?:https?|ftp)://)" +
                    # user:pass authentication
                    "(?:\\S+(?::\\S*)?@)?" +
                    "(?:" +
                    # IP address exclusion
                    # private & local networks
                    "(?!(?:10|127)(?:\\.\\d{1,3}){3})" +
                    "(?!(?:169\\.254|192\\.168)(?:\\.\\d{1,3}){2})" +
                    "(?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})" +
                    # IP address dotted notation octets
                    # excludes loopback network 0.0.0.0
                    # excludes reserved space >= 224.0.0.0
                    # excludes network & broacast addresses
                    # (first & last IP address of each class)
                    "(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])" +
                    "(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}" +
                    "(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))" +
                "|" +
                    # host name
                    "(?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)" +
                    # domain name
                    "(?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*" +
                    # TLD identifier
                    "(?:\\.(?:[a-z\\u00a1-\\uffff]{2,}))" +
                    # TLD may end with dot
                    "\\.?" +
                    ")" +
                    # port number
                    "(?::\\d{2,5})?" +
                    # resource path
                    "(?:[/?#]\\S*)?" +
                "$", "i"
            )
            return re_weburl.test(val)

    }
    checksley.updateValidators(validators)

    # Taiga Plugins
    $rootscope.contribPlugins = @.taigaContribPlugins
    $rootscope.adminPlugins = _.filter(@.taigaContribPlugins, {"type": "admin"})
    $rootscope.authPlugins = _.filter(@.taigaContribPlugins, {"type": "auth"})
    $rootscope.userSettingsPlugins = _.filter(@.taigaContribPlugins, {"type": "userSettings"})

    lang = null

    $rootscope.$on "$translateChangeEnd", (e, ctx) ->
        if lang != ctx.language
            lang = ctx.language
            i18nInit(lang, $translate)
            # RTL
            rtlLanguages = $tgConfig.get("rtlLanguages", [])
            $rootscope.isRTL = rtlLanguages.indexOf(lang) > -1

            legacy = document.querySelector('tg-legacy')
            legacy.translations = {
                translationTable: $translate.getTranslationTable(lang),
                lan: lang
            }

    $events.setupConnection()

    # Load user
    if $auth.isAuthenticated()
        user = $auth.getUser()

    # Analytics
    $analytics.initialize()

    # Tag Manager
    $tagManager.initialize()

    # UserPilot
    $userPilot.initialize()
    $userPilot.identify()

    # Initialize error handling service when location change start
    $rootscope.$on '$locationChangeStart',  (event) ->
        errorHandlingService.init()

        if lightboxService.getLightboxOpen().length
            event.preventDefault()

            lightboxService.closeAll()

    # On the first page load the loader is painted in `$routeChangeSuccess`
    # because we need to hide the tg-navigation-bar.
    # In the other cases the loader is in `$routeChangeSuccess`
    # because `location.noreload` prevent to execute this event.
    un = $rootscope.$on '$routeChangeStart',  (event, next) ->
        if next.loader
            loaderService.start(true)

        un()

    $rootscope.$on '$routeChangeSuccess', (event, next) ->
        if projectService.project?.get('blocked_code')
            errorHandlingService.block()

        if next.loader
            loaderService.start(true)

        if next.access && next.access.requiresLogin
            if !$auth.isAuthenticated()
                $location.path($navUrls.resolve("login"))

        if next.title or next.description
            title = $translate.instant(next.title or "")
            description = $translate.instant(next.description or "")
            appMetaService.setAll(title, description)

        if next.mobileViewport
            appMetaService.addMobileViewport()
        else
            appMetaService.removeMobileViewport()

        if next.disableHeader
            navigationBarService.disableHeader()
        else
            navigationBarService.enableHeader()

# Config for infinite scroll
angular.module('infinite-scroll').value('THROTTLE_MILLISECONDS', 500)

# Load modules
pluginsWithModule = _.filter(@.taigaContribPlugins, (plugin) -> plugin.module)
pluginsModules = _.map(pluginsWithModule, (plugin) -> plugin.module)

modules = [
    # Main Global Modules
    "taigaBase",
    "taigaCommon",
    "taigaResources",
    "taigaResources2",
    "taigaAuth",
    "taigaEvents",

    # Specific Modules
    "taigaHome",
    "taigaNavigationBar",
    "taigaProjects",
    "taigaRelatedTasks",
    "taigaBacklog",
    "taigaTaskboard",
    "taigaKanban",
    "taigaIssues",
    "taigaUserStories",
    "taigaTasks",
    "taigaTeam",
    "taigaWiki",
    "taigaSearch",
    "taigaAdmin",
    "taigaProject",
    "taigaUserSettings",
    "taigaFeedback",
    "taigaPlugins",
    "taigaIntegrations",
    "taigaComponents",

    # new modules
    "taigaProfile",
    "taigaHome",
    "taigaUserTimeline",
    "taigaExternalApps",
    "taigaDiscover",
    "taigaHistory",
    "taigaNotifications",
    "taigaWikiHistory",
    "taigaEpics",
    "taigaUtils"

    # template cache
    "templates",

    # Vendor modules
    "ngSanitize",
    "ngRoute",
    "ngAnimate",
    "ngAria",
    "pascalprecht.translate",
    "infinite-scroll",
    "tgRepeat",
].concat(pluginsModules)

# Main module definition
module = angular.module("taiga", modules)

module.config([
    "$routeProvider",
    "$locationProvider",
    "$httpProvider",
    "$provide",
    "$tgEventsProvider",
    "$compileProvider",
    "$translateProvider",
    "$translatePartialLoaderProvider",
    "$animateProvider",
    "$logProvider"
    configure
])

module.run([
    "$log",
    "$rootScope",
    "$tgAuth",
    "$tgEvents",
    "$tgAnalytics",
    "$tgTagManager",
    "$tgUserPilot",
    "$translate",
    "$tgLocation",
    "$tgNavUrls",
    "tgAppMetaService",
    "tgLoader",
    "tgNavigationBarService",
    "tgErrorHandlingService",
    "lightboxService",
    "$tgConfig",
    "tgProjectService",
    init
])
