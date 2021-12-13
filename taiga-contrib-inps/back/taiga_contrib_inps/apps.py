###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.apps import AppConfig
from django.conf.urls import url
from django.conf import settings
from django.http import HttpResponseNotFound


class TaigaContribINPSAppConfig(AppConfig):
    name = "taiga_contrib_inps"
    verbose_name = "Taiga contrib INPS customization App Config"

    def ready(self):

        # Monkey patch IssueViewSet

        from taiga.projects.issues.api import IssueViewSet
        from taiga.projects.issues.models import Issue
        from taiga.permissions.services import user_has_perm
        from django.db.models import Q, Subquery
        from taiga.projects.models import Project
        from taiga.base.api.utils import get_object_or_error

        prev_issue_viewset_get_queryset = IssueViewSet.get_queryset

        def get_queryset(self):
            qs = prev_issue_viewset_get_queryset(self)

            project_id = self.request.QUERY_PARAMS.get("project", None)

            if project_id is None:
                issue_pk = self.kwargs.get('pk')
                if issue_pk:
                    project_id = Issue.objects.get(id=issue_pk).project_id

            if self.request.user.is_superuser:
                return qs

            if project_id:
                project = get_object_or_error(
                    Project, self.request.user, id=project_id)
                if user_has_perm(self.request.user, "modify_issue", project):
                    return qs

            public_issue_ids_subquery = Subquery(
                IssueVisibility.objects.filter(is_public=True).values('issue_id'))
            if self.request.user.is_anonymous:
                qs = qs.filter(Q(id__in=public_issue_ids_subquery))
            else:
                qs = qs.filter(Q(id__in=public_issue_ids_subquery)
                               | Q(owner=self.request.user))
            return qs

        IssueViewSet.get_queryset = get_queryset

        # Monkey patch IssueViewSet - Issue Serialization with visibility

        from .serializers import ExtIssueNeighborsSerializer, ExtIssueListSerializer, ExtIssueSerializer

        def ext_get_serializer_class(self, *args, **kwargs):
            if self.action in ["retrieve", "by_ref"]:
                return ExtIssueNeighborsSerializer

            if self.action == "list":
                return ExtIssueListSerializer

            return ExtIssueSerializer

        IssueViewSet.get_serializer_class = ext_get_serializer_class

        # Monkey patch IssueViewSet - Update Issue visibility

        from .models import IssueVisibility
        from taiga.base.utils.db import get_object_or_none

        prev_issue_viewset_update = IssueViewSet.update

        def ext_update(self, request, *args, **kwargs):

            is_public_param = request.DATA.get('is_public', None)
            issue_obj = self.get_object_or_none()
            if is_public_param is not None and issue_obj:
                self.check_permissions(self.request, "update", issue_obj)
                visibility = get_object_or_none(
                    IssueVisibility, issue=issue_obj)
                if visibility is not None:
                    visibility.is_public = is_public_param
                else:
                    visibility = IssueVisibility(
                        issue=issue_obj, is_public=is_public_param)
                visibility.save()
                request.DATA['is_public'] = None

            return prev_issue_viewset_update(self, request, *args, **kwargs)

        IssueViewSet.update = ext_update

        # Monkey patch ProjectTimeline

        from taiga.timeline.api import ProjectTimeline
        from .timeline import services as timeline_services

        def get_timeline(self, project):
            # the methods called by get_project_timeline have been overridden in
            # the timeline/services.py file
            return timeline_services.get_project_timeline(
                project, accessing_user=self.request.user
            )

        ProjectTimeline.get_timeline = get_timeline

        # Register signals
        # TODO Without this line no signal is imported
        # See https://github.com/taigaio/taiga-contrib-slack/blob/master/back/taiga_contrib_slack/apps.py

        # Register SPID urls
        SPID_URLS_PREFIX = getattr(settings, "SPID_URLS_PREFIX", "spid/")

        if "djangosaml2_spid" in settings.INSTALLED_APPS:
            from django.urls import include, path
            from taiga.urls import urlpatterns
            import djangosaml2_spid.urls
            from spid_inps.views import AssertionConsumerServiceView
            import spid_inps.urls

            urlpatterns += [
                path(f"{SPID_URLS_PREFIX}/", include(spid_inps.urls)),
                path(
                    settings.SPID_ACS_URL_PATH,
                    AssertionConsumerServiceView.as_view(),
                    name="saml2_acs",
                ),
            ]

            urlpatterns += [
                path(
                    "",
                    include(
                        (
                            djangosaml2_spid.urls,
                            "djangosaml2_spid",
                        )
                    ),
                ),
            ]

        # Register plugin

        from .views import ExchangeTokenView
        from taiga.urls import urlpatterns

        urlpatterns.append(
            url(
                f"{SPID_URLS_PREFIX}/exchange_token/",
                ExchangeTokenView.as_view(),
                name="exchange_token_view",
            )
        )

        # Monkey patch User Create Project Permissions - attribute serialization
        from taiga.users.api import UsersViewSet
        from .serializers import ExtUserAdminSerializer
        from .validators import ExtUserValidator, ExtAdminUserValidator
        UsersViewSet.admin_serializer_class = ExtUserAdminSerializer
        UsersViewSet.validator_class = ExtUserValidator
        UsersViewSet.admin_validator_class = ExtAdminUserValidator

        # Monkey patch User Create Project Permissions - permission check
        from taiga.projects.permissions import ProjectPermission
        from taiga.base.api.permissions import IsSuperUser, IsAuthenticated
        from taiga.export_import.permissions import ImportExportPermission

        ProjectPermission.create_perms = IsSuperUser() if getattr(settings, 'ONLY_SUPERUSER_CAN_CREATE_PROJECT',
                                                                  True) else IsAuthenticated()
        ImportExportPermission.create_perms = IsSuperUser() if getattr(settings, 'ONLY_SUPERUSER_CAN_CREATE_PROJECT',
                                                                       True) else IsAuthenticated()

        # Monkey patch Attachments External User permissions
        from taiga.base.api.permissions import HasProjectPerm
        from taiga.projects.attachments.permissions import IssueAttachmentPermission, CommentAttachmentPerm
        from taiga.base.api.permissions import PermissionComponent

        class IsIssueOwnerPerm(PermissionComponent):
            def check_permissions(self, request, view, obj=None):
                if request.user.is_authenticated and request.DATA['object_id']:
                    issue = Issue.objects.get(pk=request.DATA['object_id'])
                    return request.user == issue.owner
                return False

        IssueAttachmentPermission.create_perms = HasProjectPerm('modify_issue') | (
            CommentAttachmentPerm() & HasProjectPerm('comment_issue')) | IsIssueOwnerPerm()

        # Monkey patch Attachments validator for size and type
        from taiga.projects.attachments.validators import AttachmentValidator
        from taiga.base.exceptions import ValidationError
        from django.utils.translation import ugettext as _
        from taiga.projects.attachments.api import BaseAttachmentViewSet
        from taiga.base import exceptions as exc
        import magic

        def validate_attached_file(self, attrs, source):
            file = attrs.get("attached_file")
            if file.size and hasattr(settings,
                                     "MAX_UPLOAD_FILE_SIZE") and settings.MAX_UPLOAD_FILE_SIZE and file.size > settings.MAX_UPLOAD_FILE_SIZE:
                raise ValidationError(_("File size is too large"))

            if file.content_type and hasattr(settings,
                                             "ATTACHMENT_MIME_TYPES") and settings.ATTACHMENT_MIME_TYPES and file.content_type not in settings.ATTACHMENT_MIME_TYPES:
                raise ValidationError(_("Mime type not supported"))
            return attrs

        AttachmentValidator.validate_attached_file = validate_attached_file

        def attachment_post_save(self, object, created=False):
            head_mime = magic.from_file(object.attached_file.path, mime=True)
            if hasattr(settings,
                       "ATTACHMENT_MIME_TYPES") and settings.ATTACHMENT_MIME_TYPES and head_mime not in settings.ATTACHMENT_MIME_TYPES:
                object.delete()
                self.post_delete(object)
                raise exc.WrongArguments(
                    _("Mime type not supported, the file is corrupted"))

            super(BaseAttachmentViewSet,self).post_save(object,created)

        BaseAttachmentViewSet.post_save = attachment_post_save

        # Monkey patch Add Project Admins in User notifications
        from taiga.projects.notifications import services as notify_service
        # from taiga.projects.history.choices import HistoryType

        prev_get_users_to_notify = notify_service.get_users_to_notify

        def ext_get_users_to_notify(obj, *, history=None, discard_users=None, live=False) -> list:
            candidates = prev_get_users_to_notify(
                obj, history=history, discard_users=discard_users, live=live)
            project = obj.get_project()
            print(vars(history))

            # Add the changer from candidates

            if discard_users and getattr(history, 'key', 'None:None').split(":", 1)[
                    0] == 'issues.issue':  # and history.get('type',None) == HistoryType.create:
                if not getattr(history, 'comment', ''):
                    candidates = frozenset().union(candidates, frozenset(set(discard_users)))

            # - Admnin of the Project
            admin_candidates = project.get_users(
                with_admin_privileges=getattr(settings, 'NOTIFY_ALL_STAFF', True))

            if (admin_candidates):
                # Remove duplicate users
                admin_candidates = set(
                    [admin for admin in admin_candidates if admin not in candidates])
                if getattr(history, 'comment', ''):
                    admin_candidates = admin_candidates - set(discard_users)

                if (admin_candidates and len(admin_candidates)):
                    return frozenset().union(candidates, frozenset(admin_candidates))

            return candidates

        notify_service.get_users_to_notify = ext_get_users_to_notify

        # Monkey patch Only Staff can delete Account
        from taiga.base.api.permissions import PermissionComponent
        from taiga.users.permissions import IsTheSameUser
        from taiga.users.permissions import UserPermission

        class hasAnyRoles(PermissionComponent):
            def check_permissions(self, request, view, obj=None):
                return request.user and len(request.user.cached_memberships)

        UserPermission.destroy_perms = IsTheSameUser() and hasAnyRoles()

        from taiga.projects.api import ProjectViewSet
        from taiga.base.api.utils import get_object_or_error
        from django.http import Http404
        from taiga.base import filters, response

        def retrieve(self, request, *args, **kwargs):
            qs = self.get_queryset()
            if self.action == "by_slug":
                self.lookup_field = "slug"
                # If we retrieve the project by slug we want to filter by user the
                # permissions and return 404 in case the user don't have access
                flt = filters.get_filter_expression_can_view_projects(
                    request.user)

                qs = qs.filter(flt)

            self.object = get_object_or_error(qs, request.user, **kwargs)

            self.check_permissions(request, 'retrieve', self.object)

            if self.object is None:
                raise Http404

            serializer = self.get_serializer(self.object)

            if not request.user or request.user.is_anonymous or not len(request.user.cached_memberships):
                if serializer.data:
                    serializer.data['members'] = []

            return response.Ok(serializer.data)

        ProjectViewSet.retrieve = retrieve

        from .views import MyUsersAPI

        urlpatterns.append(
            url(
                "api/v1/all_users/(?P<pk>[^/.]+)/contacts$",
                MyUsersAPI.as_view(),
                name="all_users",
            )
        )


        # Disable the default Taiga auth Routes
        urlpatterns.insert(0, url('api/v1/auth/register', self.render_404))
        urlpatterns.insert(0, url('api/v1/auth', self.render_404))

        from taiga.projects.validators import _MemberBulkValidator
        from taiga.base.api.fields import validate_user_email_allowed_domains, InvalidEmailValidationError
        from taiga.users.models import User

        def validate_username(self, attrs, source):
            username = attrs.get(source)
            try:
                validate_user_email_allowed_domains(username)
            except InvalidEmailValidationError:
                # If the validation comes from a request let's check the user is a valid contact
                request = self.context.get("request", None)
                if request is not None and request.user.is_authenticated:
                    all_usernames = User.objects.all().values_list("username", flat=True)
                    valid_usernames = set(all_usernames)
                    if username not in valid_usernames:
                        raise ValidationError(
                            _("The user must be a valid contact"))

            return attrs

        _MemberBulkValidator.validate_username = validate_username

    def render_404(self, request):
        return HttpResponseNotFound('<h1>Page not found</h1>')
