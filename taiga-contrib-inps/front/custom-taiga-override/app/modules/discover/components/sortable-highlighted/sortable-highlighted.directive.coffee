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

SortableHighlightedDirective = () ->
    return {
        templateUrl: "discover/components/sortable-highlighted/sortable-highlighted.html",
        scope: {
            loading: "=",
            highlighted: "=",
            orderBy: "=",
            isAdmin: "="
        }
    }

SortableHighlightedDirective.$inject = []

angular.module("taigaDiscover").directive("tgSortableHighlighted", SortableHighlightedDirective)
