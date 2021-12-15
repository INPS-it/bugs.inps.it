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

SortDiscoverProjectsDirective = (currentUserService, projectsService, discoverProjectsService) ->
    link = (scope, el, attrs, ctrl) ->

        draggableElementsClassName = 'highlighted-draggable-project'

        if currentUserService.isAdmin() == false 
            return

        itemEl = null

        drake = dragula([el[0]], {
            copySortSource: false,
            copy: false,
            mirrorContainer: el[0],
            moves: (item) -> return $(item).hasClass(draggableElementsClassName) # La libreria muove l'elemento se ha la classe .highlighted-project
        })

        drake.on 'dragend', (item) ->
            itemEl = $(item)
            project = itemEl.scope().project
            index = itemEl.index()

            # Il seguente algoritmo trasforma la mappa di progetti in un array di id progetti
            # Elimina dall'array l'id del progetto che si sta spostando
            # Inserisce l'id del progetto che si sta spostando all'index fornito da itemEl.index() - funzionalità fornita da dragulaJS
            sorted_project_ids = _.map(scope.projects.toJS(), (p) -> p.id)
            sorted_project_ids = _.without(sorted_project_ids, project.get("id"))
            sorted_project_ids.splice(index, 0, project.get('id'))

            # Ricostruisco l'array di dati da inviare al servizio backend
            sortData = []

            for value, index in sorted_project_ids
                sortData.push({"project_id": value, "order":index})

            projectsService.bulkUpdateCustomProjectsOrder(sortData).then (result) ->
                discoverProjectsService.resetSearchList()
                scope.search()
            .catch (error) ->
                console.error("Si è verificato un errore nell'impostare l'ordine dei progetti.")
                console.error(error)

        scroll = autoScroll(window, {
            margin: 20,
            pixels: 30,
            scrollWhenOutside: true,
            autoScroll: () ->
                return this.down && drake.dragging
        })

        scope.$on "$destroy", ->
            el.off()
            drake.destroy()

    directive = {
        scope: {
            projects: "=tgSortDiscoverProjects",
            search: "&"
        },
        link: link
    }

    return directive

angular.module("taigaProjects").directive("tgSortDiscoverProjects", ["tgCurrentUserService", "tgProjectsService", "tgDiscoverProjectsService", SortDiscoverProjectsDirective])
