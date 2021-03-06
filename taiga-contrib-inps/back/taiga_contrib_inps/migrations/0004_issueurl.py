###
# license-start
# 
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# 
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

# Generated by Django 2.2.24 on 2021-12-20 15:13

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('issues', '0009_auto_20200615_0811'),
        ('taiga_contrib_inps', '0003_auto_20211209_1132'),
    ]

    operations = [
        migrations.CreateModel(
            name='IssueUrl',
            fields=[
                ('issue', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, primary_key=True, serialize=False, to='issues.Issue')),
                ('issue_url', models.CharField(max_length=1024)),
            ],
        ),
    ]
