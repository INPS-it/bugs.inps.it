###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###


from taiga.base.api.reverse import reverse
from ..factories import MembershipFactory, ProjectFactory, UserFactory
from taiga.projects.history import services as history_services
import pytest


pytestmark = pytest.mark.django_db(transaction=True, reset_sequences=True)

MEMBERS_PERMISSIONS = [
    ('view_project', ('View project')),
    # Issue permissions
    ('view_issues', ('View issues')),
    ('add_issue', ('Add issue')),
    ('modify_issue', ('Modify issue')),
    ('comment_issue', ('Comment issue')),
    ('delete_issue', ('Delete issue')),
]


def test_timeline_visibility(client):

    # Owner - Editor
    owner_user = UserFactory.create()
    # Editor
    editor_user = UserFactory.create()
    # Viewer
    not_member_user = UserFactory.create()
    # SuperUser
    super_user = UserFactory.create(is_superuser=True)

    project = ProjectFactory.create(owner=editor_user)
    history_services.take_snapshot(project, user=project.owner)

    # Create Membership
    MembershipFactory.create(project=project,
                             user=owner_user,
                             role__project=project,
                             role__permissions=list(map(lambda x: x[0], MEMBERS_PERMISSIONS)))

    MembershipFactory.create(project=project,
                             user=editor_user,
                             role__project=project,
                             role__permissions=list(map(lambda x: x[0], MEMBERS_PERMISSIONS)))

    url = reverse('project-timeline-detail', kwargs={"pk": project.pk})

    # superuser can view all events
    client.force_login(super_user)
    response = client.get(url)
    assert response.status_code == 200
    assert len(response.data)
    assert response.data[len(response.data) -
                         1]['event_type'] == 'projects.project.create'

    # owner can view event
    client.force_login(owner_user)
    response = client.get(url)
    assert response.status_code == 200
    assert len(response.data)
    assert response.data[len(response.data) -
                         1]['event_type'] == 'projects.project.create'

    # editor can view event on project
    client.force_login(editor_user)
    response = client.get(url)
    assert response.status_code == 200
    assert len(response.data)
    assert response.data[len(response.data) -
                         1]['event_type'] == 'projects.project.create'

    # viewer can view event on project
    client.force_login(not_member_user)
    response = client.get(url)
    assert response.status_code == 403
