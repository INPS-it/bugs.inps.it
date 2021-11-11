###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from unittest.mock import patch

from taiga.projects.issues.models import Issue
from ..factories import IssueFactory, MembershipFactory, ProjectFactory, UserFactory, IssueVisibilityFactory, \
    IssueStatusFactory
from django.urls import reverse
from taiga.base.utils import json
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test.client import MULTIPART_CONTENT
import pytest

pytestmark = pytest.mark.django_db(transaction=True, reset_sequences=True)

VIEWER_PERMISSIONS = [
    ('view_project', ('View project')),
    # Issue permissions
    ('view_issues', ('View issues')),
    ('add_issue', ('Add issue')),
    ('comment_issue', ('Comment issue')),
]
MEMBERS_PERMISSIONS = [
    ('view_project', ('View project')),
    # Issue permissions
    ('view_issues', ('View issues')),
    ('add_issue', ('Add issue')),
    ('modify_issue', ('Modify issue')),
    ('comment_issue', ('Comment issue')),
    ('delete_issue', ('Delete issue')),
]


def test_superuser_can_view_all_issues(client):
    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)

    owner = UserFactory.create()
    issue = IssueFactory.create(project=project, owner=owner)

    url = reverse("issues-list")

    client.force_login(super_user)
    response = client.get(url)

    assert response.status_code == 200
    assert len(response.data)
    assert response.data[0]['id'] == issue.id

    visibility = IssueVisibilityFactory.build(issue=issue, is_public=True)
    visibility.save()

    response = client.get(url)

    assert response.status_code == 200
    assert len(response.data)
    assert response.data[0]['id'] == issue.id


def test_user_with_edit_permission_can_view_all(client):
    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)

    issue_owner = UserFactory.create()
    issue = IssueFactory.create(project=project, owner=issue_owner)

    editor = UserFactory.create(is_superuser=False)
    MembershipFactory.create(project=project,
                             user=editor,
                             role__project=project,
                             role__permissions=list(map(lambda x: x[0], MEMBERS_PERMISSIONS)))

    url = reverse("issues-list")
    client.force_login(editor)

    response = client.get(url+'?project=' + str(project.id))

    assert response.status_code == 200
    assert len(response.data)
    assert response.data[0]['id'] == issue.id

    visibility = IssueVisibilityFactory.build(issue=issue, is_public=True)
    visibility.save()

    response = client.get(url)

    assert response.status_code == 200
    assert len(response.data)
    assert response.data[0]['id'] == issue.id


def test_user_with_no_edit_permission_cannot_view_all(client):
    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)

    issue_owner = UserFactory.create()
    issue = IssueFactory.create(project=project, owner=issue_owner)

    viewer = UserFactory.create(is_superuser=False)
    MembershipFactory.create(project=project, user=viewer,
                             role__project=project,
                             role__permissions=list(map(lambda x: x[0], VIEWER_PERMISSIONS)))

    url = reverse("issues-list")
    client.force_login(viewer)

    response = client.get(url+'?project=' + str(project.id))

    assert response.status_code == 200
    assert not len(response.data)

    # With is_public=true the issue is public
    visibility = IssueVisibilityFactory.build(issue=issue, is_public=True)
    visibility.save()

    response = client.get(url)

    assert response.status_code == 200
    assert len(response.data)
    assert response.data[0]['id'] == issue.id

    # Viewer can view their issue
    issue = IssueFactory.create(project=project, owner=viewer)

    response = client.get(url + '?project=' + str(project.id))
    assert response.status_code == 200
    assert len(response.data) == 2


def test_update_issue_visibility(client):

    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)

    issue_owner = UserFactory.create()
    MembershipFactory.create(project=project,
                             user=issue_owner,
                             role__project=project,
                             role__permissions=list(map(lambda x: x[0], MEMBERS_PERMISSIONS)))
    issue = IssueFactory.create(project=project, owner=issue_owner)

    url = reverse('issues-detail', kwargs={"pk": issue.pk})

    # owner editor switch to Public
    client.force_login(issue_owner)
    data = {"is_public": True, "version": issue.version}
    response = client.patch(url, json.dumps(
        data), content_type='application/json')

    assert response.status_code == 200
    assert response.data['is_public'] == True

    # owner editor switch to False
    data = {"is_public": False, "version": issue.version}
    response = client.patch(url, json.dumps(
        data), content_type='application/json')

    assert response.status_code == 200
    assert response.data['is_public'] == False

    # superuser switch to Public
    client.force_login(super_user)
    data = {"is_public": True, "version": issue.version}
    response = client.patch(url, json.dumps(
        data), content_type='application/json')

    assert response.status_code == 200
    assert response.data['is_public'] == True

    # superuser switch to False
    data = {"is_public": False, "version": issue.version}
    response = client.patch(url, json.dumps(
        data), content_type='application/json')

    assert response.status_code == 200
    assert response.data['is_public'] == False

    # owner viewer cannot switch
    viewer_owner = UserFactory.create()
    MembershipFactory.create(project=project,
                             user=viewer_owner,
                             role__project=project,
                             role__permissions=list(map(lambda x: x[0], VIEWER_PERMISSIONS)))

    issue = IssueFactory.create(project=project, owner=viewer_owner)

    url = reverse('issues-detail', kwargs={"pk": issue.pk})
    client.force_login(viewer_owner)
    data = {"is_public": True, "version": issue.version}
    response = client.patch(url, json.dumps(
        data), content_type='application/json')

    assert response.status_code == 403


def test_issue_status_on_create(client):
    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)
    triage_status = IssueStatusFactory.create(
        name='triage', slug='triage', project=project)

    issue = Issue.objects.create(owner=super_user, project=project)
    url = reverse('issues-detail', kwargs={"pk": issue.pk})
    client.force_login(super_user)
    response = client.get(url)

    assert response.status_code == 200
    assert response.data['status'] == triage_status.id

    # cannot modify triage status slug
    triage_status.slug = 'new-slug'
    triage_status.save()
    url = reverse('issue-statuses-detail', kwargs={"pk": triage_status.pk})
    response = client.get(url)
    assert response.status_code == 200
    assert response.data['slug'] == 'triage'


def test_issue_upload_attachments(client):
    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)
    issue = Issue.objects.create(owner=super_user, project=project)

    url = reverse('issue-attachments-list')
    client.force_login(super_user)

    attachment_data = {"description": "test",
                       "object_id": issue.id,
                       "project": project.id,
                       "attached_file": SimpleUploadedFile("test.txt", b"test")}
    attachment_data2 = {"description": "test",
                        "object_id": issue.id,
                        "project": project.id,
                        "attached_file": SimpleUploadedFile("test2.txt", b"test")}
    attachment_data3 = {"description": "test",
                        "object_id": issue.id,
                        "project": project.id,
                        "attached_file": SimpleUploadedFile("test3.txt", b"test")}

    with patch('django.conf.settings.ATTACHMENT_MIME_TYPES', ["text/plain"]):
        response = client.post(
            url, data=attachment_data, follow_redirects=True, content_type=MULTIPART_CONTENT)
        assert response.status_code == 201

    # status code 400 if file size > MAX_UPLOAD_FILE_SIZE
    with patch('django.conf.settings.MAX_UPLOAD_FILE_SIZE', 1):
        response = client.post(url, data=attachment_data2,
                               follow_redirects=True, content_type=MULTIPART_CONTENT)
        assert response.status_code == 400

    # status code 400 if file mimetype not in ATTACHMENT_MIME_TYPES
    with patch('django.conf.settings.MAX_UPLOAD_FILE_SIZE', 10485760):
        with patch('django.conf.settings.ATTACHMENT_MIME_TYPES', ["image/jpg"]):
            response = client.post(
                url, data=attachment_data3, follow_redirects=True, content_type=MULTIPART_CONTENT)
            assert response.status_code == 400


def test_issue_attachment_header_mime(client):
    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)
    issue = Issue.objects.create(owner=super_user, project=project)

    url = reverse('issue-attachments-list')
    client.force_login(super_user)

    file = SimpleUploadedFile("test.txt", b"test", content_type='image/png')

    attachment_data = {"description": "test",
                       "object_id": issue.id,
                       "project": project.id,
                       "attached_file": file}

    # status code 400 if header mimetype not in ATTACHMENT_MIME_TYPES
    with patch('django.conf.settings.MAX_UPLOAD_FILE_SIZE', 10485760):
        with patch('django.conf.settings.ATTACHMENT_MIME_TYPES', ["image/png"]):
            response = client.post(url, data=attachment_data, follow_redirects=True,
                                   content_type=MULTIPART_CONTENT)
            assert response.status_code == 400


def test_external_user_upload_attachments(client):
    super_user = UserFactory.create(is_superuser=True)
    project = ProjectFactory.create(owner=super_user)
    super_user_issue = Issue.objects.create(owner=super_user, project=project)

    external_user = UserFactory.create(is_superuser=False)
    external_user_issue = Issue.objects.create(
        owner=external_user, project=project)

    url = reverse('issue-attachments-list')
    client.force_login(external_user)

    with patch('django.conf.settings.MAX_UPLOAD_FILE_SIZE', 10485760):
        with patch('django.conf.settings.ATTACHMENT_MIME_TYPES', ["text/plain"]):

            # status code 403 if external user is not issue owner
            attachment_data1 = {"description": "test1",
                                "object_id": super_user_issue.id,
                                "project": project.id,
                                "attached_file": SimpleUploadedFile("test.txt", b"test")}

            response = client.post(url, data=attachment_data1, follow_redirects=True,
                                   content_type=MULTIPART_CONTENT)
            assert response.status_code == 403

            # status code 201 if external user is owner
            attachment_data2 = {"description": "test2",
                                "object_id": external_user_issue.id,
                                "project": project.id,
                                "attached_file": SimpleUploadedFile("test.txt", b"test")}

            response = client.post(url, data=attachment_data2, follow_redirects=True,
                                   content_type=MULTIPART_CONTENT)
            assert response.status_code == 201

            # status code 401 if user is not authenticated
            client.logout()

            attachment_data3 = {"description": "test3",
                                "object_id": external_user_issue.id,
                                "project": project.id,
                                "attached_file": SimpleUploadedFile("test.txt", b"test")}

            response = client.post(url, data=attachment_data3, follow_redirects=True,
                                   content_type=MULTIPART_CONTENT)
            assert response.status_code == 401
