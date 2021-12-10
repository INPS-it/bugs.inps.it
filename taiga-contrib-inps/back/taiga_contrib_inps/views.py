###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###
from .models import ProjectCustomOrder
from taiga.projects.models import Membership, Project
from taiga.base.api.permissions import ResourcePermission
from taiga.base.api.generics import RetrieveAPIView

from taiga.base.exceptions import MethodNotAllowed
from taiga.base.decorators import list_route
from taiga.users import utils as user_utils
from taiga.users import serializers
from taiga.base import response
from taiga.users.models import User
from taiga.base.api.utils import get_object_or_404
import time

from django.views import View
from django.http import *
from django.conf import settings
from .services import ext_make_auth_response_data
import json


class ExchangeTokenView(View):

    def post(self, request, *args, **kwargs):
        _args = ("partial_code", "")
        partial_code = request.POST.get(*_args)
        # seconds
        max_duration = getattr(settings, "TOKEN_CHALLENGE_MAX_DURATION", "20")

        if partial_code and partial_code in request.session:
            session_data = request.session[partial_code]
            max_time = int(max_duration) + int(session_data)
            if int(time.time()) < max_time:
                user = request.user
                data = ext_make_auth_response_data(user)
                data["roles"] = list(data["roles"])
                del request.session[partial_code]
                return JsonResponse(data, safe=False)

        return HttpResponseForbidden()


def user_is_admin(user):
    mm = Membership.objects.filter(user=user, is_admin=True)
    if not len(mm):
        return False
    else:
        return True


class MyUsersAPI(RetrieveAPIView):
    model = User
    serializer_class = serializers.UserAdminSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        qs = qs.prefetch_related("memberships")
        qs = user_utils.attach_extra_info(qs, user=self.request.user)
        return qs

    def retrieve(self, request, *args, **kwargs):

        if not user_is_admin(request.user):
            return response.Forbidden()

        user = get_object_or_404(User, **kwargs)

        qs = User.objects.filter(is_active=True)
        qs = qs.exclude(id=user.id)

        exclude_project = request.GET.get('exclude_project', None)
        if exclude_project:
            qs = qs.exclude(projects__id=exclude_project)

        object_list = qs.extra(
            select={"complete_user_name": "concat(full_name, username)"}).order_by("complete_user_name")

        page = self.paginate_queryset(object_list)
        if page is not None:
            serializer = self.serializer_class(
                page.object_list, many=True)
        else:
            serializer = self.serializer_class(object_list, many=True)

        return response.Ok(serializer.data)


from taiga.base.api.views import APIView

class bulk_update_projects_custom_order(APIView):
    def post(self, request, *args, **kwargs):
        """Creates or updates the custom projects order that can be used in the discover page.
        """
        if not user_is_admin(request.user):
            return response.Forbidden()

        order_created_response = []
        json_request = json.loads(request.body.decode('utf-8'))

        for order_map in json_request:
            project_instance = Project.objects.get(pk=order_map.get('project_id'))
            order = order_map.get('order')

            defaults = {
                'project': project_instance,
                'order': order
            }

            order_created = ProjectCustomOrder.objects.update_or_create(defaults, project=project_instance)

            order_created_response.append(str(order_created[0]))

        return JsonResponse(json.dumps(order_created_response), safe=False)
        
bulk_update_projects_custom_order_view = bulk_update_projects_custom_order.as_view()
