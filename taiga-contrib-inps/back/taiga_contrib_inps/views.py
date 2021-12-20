###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###
from .models import ProjectCustomOrder
from taiga.projects.models import Membership, Project, Priority, Severity, IssueType, IssueStatus
from taiga.projects.issues.models import Issue
from taiga.projects.attachments import models as attachments_models
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
from django.contrib.auth import logout
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
                logout(request)
                return JsonResponse(data, safe=False)

        logout(request)
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

class MoveIssueView(APIView):
    def post(self, request, *args, **kwargs):
        """Moves an issue to a different project.
        """
        if not user_is_admin(request.user):
            return response.Forbidden()

        json_request = json.loads(request.body.decode('utf-8'))
        issue_data = json_request['issue_data']

        old_project_id = issue_data.get('project')
        new_project_id = json_request['project_id']
        issue_id = issue_data.get('id')
        old_owner = issue_data.get('owner')

        # Let's retrieve the issue:
        issue = Issue.objects.get(id=issue_id)
        project = Project.objects.get(id=new_project_id)
        
        try:
            owner = User.objects.get(id=old_owner)
        except DoesNotExist:
            owner = None

        
        old_status = IssueStatus.objects.get(project_id=old_project_id,id=issue_data.get('status'))

        try:
            target_status = IssueStatus.objects.get(project_id=new_project_id,slug=old_status.slug)
        except IssueStatus.DoesNotExist:
            # Status not found, we have to create a new status with the same data of the old status
            target_status = IssueStatus.create(name=old_status.name,order=10,is_closed=old_status.is_closed,color=old_status.color,project_id=new_project_id,slug=old_status.slug)

        old_severity = Severity.objects.get(project_id=old_project_id, id=issue_data.get('severity'))

        try:
            target_severity = Severity.objects.get(project_id=new_project_id,name=old_severity.name)
        except Severity.DoesNotExist:
            # Severity not found, we have to create a new status with the same data of the old status
            target_severity = Severity.create(name=old_severity.name,order=10,color=old_severity.color,project_id=new_project_id)

        old_priority = Priority.objects.get(project_id=old_project_id, id=issue_data.get('priority'))

        try:
            target_priority = Priority.objects.get(project_id=new_project_id,name=old_priority.name)
        except Priority.DoesNotExist:
            # priority not found, we have to create a new status with the same data of the old status
            target_priority = Priority.create(name=old_priority.name,order=10,color=old_priority.color,project_id=new_project_id)

        old_issue_type = IssueType.objects.get(project_id=old_project_id, id=issue_data.get('type'))

        try:
            target_type = IssueType.objects.get(project_id=new_project_id,name=old_issue_type.name)
        except IssueType.DoesNotExist:
            # type not found, we have to create a new status with the same data of the old status
            target_type = IssueType.create(name=old_issue_type.name,order=10,color=old_issue_type.color,project_id=new_project_id)
        

        # Let's update the issue
        issue.status = target_status
        issue.project = project
        issue.owner = owner
        issue.severity = target_severity
        issue.priority = target_priority
        issue.type = target_type

        issue.save()

        # Let's find and update attachments
        attachments = attachments_models.Attachment.objects.filter(object_id=issue_id, project=old_project_id)

        if attachments.count() > 0:

            for attachment in attachments:
                attachment.project = project
                attachment.save()

        return JsonResponse(json_request, safe=False)
