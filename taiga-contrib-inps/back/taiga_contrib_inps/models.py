###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

import json

from django.db import models

from taiga.projects.issues.models import Issue
from taiga.projects.models import Project


class IssueVisibility(models.Model):
    issue = models.OneToOneField(
        Issue,
        on_delete=models.CASCADE,
        primary_key=True,
    )

    is_public = models.BooleanField(null=False, blank=False, default=False)

    class Meta:
        app_label = 'taiga_contrib_inps'

    def __str__(self):
        return "%s public: %s" % (self.issue.subject, self.is_public)


class ProjectCustomOrder(models.Model):
    """External model that enables projects to be custom ordered by admins in the Discover page.

    Order field will default to project id, it will be then updated by the order customization in the frontend.
    """
    project = models.OneToOneField(
        Project,
        on_delete=models.CASCADE,
        primary_key=True
    )

    order = models.IntegerField(null=False, blank=False)

    class Meta:
        app_label = 'taiga_contrib_inps'
        constraints = [
            models.UniqueConstraint(fields=['project', 'order'], name='unique_project_order'),
        ]

    def __str__(self):
        return "%s order: %s" % (self.project.name, self.order)
    
    def __repr__(self):
        return "%s order: %s" % (self.project.name, self.order)


def set_public_permissions_to_scrum_project(instance, **kwargs):
    if not instance.pk:
        instance.public_permissions = ['view_us', 'view_wiki_links', 'view_milestones', 'view_project', 'view_tasks', 'view_wiki_pages', 'view_issues', 'add_issue','comment_issue', 'view_epics']

models.signals.pre_save.connect(set_public_permissions_to_scrum_project, sender=Project, dispatch_uid="set_public_permissions_to_scrum_project")
