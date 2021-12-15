###
# license-start
# 
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# 
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

# Generated by Django 2.2.24 on 2021-12-09 11:32

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('projects', '0067_auto_20201230_1237'),
        ('taiga_contrib_inps', '0002_issuevisibility'),
    ]

    operations = [
        migrations.CreateModel(
            name='ProjectCustomOrder',
            fields=[
                ('project', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, primary_key=True, related_name='custom_order', serialize=False, to='projects.Project')),
                ('order', models.IntegerField()),
            ],
        ),
        migrations.AddConstraint(
            model_name='projectcustomorder',
            constraint=models.UniqueConstraint(fields=('project', 'order'), name='unique_project_order'),
        ),
    ]
