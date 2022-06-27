###
# license-start
#
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021 INPS - Istituto Nazionale di Previdenza Sociale
###

from setuptools import setup, find_packages

setup(
    name="taiga-contrib-inps",
    version=":versiontools:taiga_contrib_inps:",
    description="The Taiga plugin for INPS customization",
    long_description="",
    keywords="taiga, inps, auth, plugin",
    author="INPS",
    url="https://github.com/INPS-it/taiga-inps-bug-tracking",
    include_package_data=True,
    packages=find_packages(),
    install_requires=[
        "djangosaml2-spid @ git+https://git@github.com/italia/spid-django.git@main#egg=djangosaml2-spid",
        "djangosaml2 < 1.5.0",
        "spid_compliant_certificates @ git+https://git@github.com/italia/spid-compliant-certificates-python.git@main#egg=spid_compliant_certificates",
    ],
    setup_requires=[
        "requests==2.25.1",
        "zipp==3.1.0",
        "versiontools >= 1.9",
    ],
    classifiers=[
        "Programming Language :: Python",
        "Development Status :: 4 - Beta",
        "Framework :: Django",
        "Intended Audience :: Developers",
        "Operating System :: OS Independent",
        "Programming Language :: Python",
        "Topic :: Internet :: WWW/HTTP",
    ],
)
