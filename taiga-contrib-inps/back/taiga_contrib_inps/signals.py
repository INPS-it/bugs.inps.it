###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from taiga.projects.issues.models import Issue
from taiga.projects.models import IssueStatus
from .models import IssueVisibility


@receiver(pre_save, sender=IssueStatus)
def set_issue_status_slug(instance, **kwargs):
    # you can only modify the name of the triage status, not its slug
    try:
        old_instance = IssueStatus.objects.get(id=instance.id)
        if old_instance.slug == "triage":
            instance.slug = "triage"
    except IssueStatus.DoesNotExist:
        return None


@receiver(post_save, sender=Issue)
def set_issue_triage_status(instance, **kwargs):
    # when an issue is created, its issue status always has to be 'triage'
    if kwargs["created"]:
        try:
            instance.status = instance.project.issue_statuses.get(
                slug="triage")
        except IssueStatus.DoesNotExist:
            instance.status = instance.project.default_issue_status
        instance.save()


@receiver(post_save, sender=Issue)
def set_visibility_to_issue(instance, **kwargs):
    if kwargs["created"]:
        visibility = IssueVisibility(issue=instance, is_public=False)
        visibility.save()
