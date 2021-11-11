###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.contrib.contenttypes.models import ContentType
from django.db.models import Model
from django.db.models import Q
from taiga.projects.issues.models import Issue
from taiga.permissions.services import user_has_perm
from django.db.models.expressions import RawSQL


def build_project_namespace(project: object):
    return "{0}:{1}".format("project", project.id)


def get_timeline(obj, namespace=None):
    assert isinstance(obj, Model), "obj must be a instance of Model"
    from taiga.timeline.models import Timeline

    ct = ContentType.objects.get_for_model(obj.__class__)
    timeline = Timeline.objects.filter(content_type=ct)

    if namespace is not None:
        timeline = timeline.filter(namespace=namespace)
    else:
        timeline = timeline.filter(object_id=obj.pk)

    timeline = timeline.order_by("-created")
    return timeline


def filter_timeline_for_user(timeline, user, namespace=None):
    # Superusers can see everything
    if user.is_superuser:
        return timeline

    # OLD: Filtering entities from public projects or entities without project
    # Reason: We don't want public projects timeline to be completely accessible
    # tl_filter = Q(project__is_private=False) | Q(project=None)

    # Filtering entities without project
    tl_filter = Q(project=None)

    # Custom issue timeline filtering: issues are only displayed if the user can access them
    issue_timeline = timeline.filter(
        data_content_type=ContentType.objects.get_by_natural_key(
            "issues", "issue")
    )
    issues_ids = set([issue.data["issue"]["id"]
                     for issue in list(issue_timeline)])

    issues = Issue.objects.filter(id__in=issues_ids)

    user_allowed_issues_ids = []
    for issue in issues:
        if (
            user_has_perm(user, "modify_issue", issue.project)
            or issue.status.slug != "triage"
            or issue.owner == user
        ):
            user_allowed_issues_ids.append(issue.id)

    tl_filter |= Q(
        data_content_type=ContentType.objects.get_by_natural_key(
            "issues", "issue"),
        data__issue__id__in=user_allowed_issues_ids,
    )

    # Filtering projects with some public parts
    # Removed issue filtering from here
    content_types = {
        # "view_project": ContentType.objects.get_by_natural_key("projects", "project"),
        "view_milestones": ContentType.objects.get_by_natural_key(
            "milestones", "milestone"
        ),
        "view_epics": ContentType.objects.get_by_natural_key("epics", "epic"),
        "view_us": ContentType.objects.get_by_natural_key("userstories", "userstory"),
        "view_tasks": ContentType.objects.get_by_natural_key("tasks", "task"),
        # "view_issues": ContentType.objects.get_by_natural_key("issues", "issue"),
        "view_wiki_pages": ContentType.objects.get_by_natural_key("wiki", "wikipage"),
        "view_wiki_links": ContentType.objects.get_by_natural_key("wiki", "wikilink"),
    }

    for content_type_key, content_type in content_types.items():
        tl_filter |= Q(
            project__anon_permissions__contains=[content_type_key],
            data_content_type=content_type,
        )

    # There is no specific permission for seeing new memberships
    membership_content_type = ContentType.objects.get_by_natural_key(
        app_label="projects", model="membership"
    )
    # tl_filter |= Q(
    #     project__anon_permissions__contains=["view_project"],
    #     data_content_type=membership_content_type,
    # )
    projects_content_type = ContentType.objects.get_by_natural_key(
        "projects", "project")
    # Filtering projects where user is member
    if not user.is_anonymous:
        for membership in user.cached_memberships:
            # Admin roles can see everything in a project
            if membership.is_admin:
                tl_filter |= Q(project=membership.project)
            else:
                data_content_types = list(
                    filter(
                        None,
                        [
                            content_types.get(a, None)
                            for a in membership.role.permissions
                        ],
                    )
                )
                data_content_types.append(membership_content_type)
                data_content_types.append(projects_content_type)
                tl_filter |= Q(
                    project=membership.project, data_content_type__in=data_content_types
                )

    timeline = timeline.filter(tl_filter)

    if namespace:
        timeline = timeline.exclude(
            id__in=_get_not_allowed_epic_related_query(user, namespace)
        )

    return timeline


def _get_not_allowed_epic_related_query(accessing_user, namespace):
    sql = """
    select tt.id
    from timeline_timeline tt
    inner join projects_project pp
    -- project of the epic's related user story
    on cast (data -> 'userstory' -> 'project' ->> 'id' as INTEGER) = pp.id
    where 
       not (
            -- Allowed for anonymous users
            'view_us' = ANY(pp.anon_permissions)
            or
            -- Allowed for registered users
            ('view_us' = ANY(pp.public_permissions) and {user_id} <> -1)
            or
            -- Allowed for a project member with a privileged role
            exists (select * from users_role ur
            inner join projects_membership pm
            ON ur.id = pm.role_id
            where pm.user_id = {user_id}
            and pm.project_id = pp.id
            and 'view_us' = ANY(ur.permissions))
        )
        and tt.namespace = '{namespace}'
        and tt.event_type = 'epics.relateduserstory.create'
    """
    accessing_user_id = accessing_user.id or - \
        1  # -1 just in case of anonymous user
    sql = sql.format(user_id=accessing_user_id, namespace=namespace)

    return RawSQL(sql, ())


def get_project_timeline(project, accessing_user=None):
    namespace = build_project_namespace(project)
    timeline = get_timeline(project, namespace)
    if accessing_user is not None:
        timeline = filter_timeline_for_user(
            timeline, accessing_user, namespace)

    return timeline
