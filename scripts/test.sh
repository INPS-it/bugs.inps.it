#!/bin/bash

PYTHONPATH="./taiga-contrib-inps/back:./taiga-back" coverage run --source=taiga-contrib-inps --omit='*tests*,*commands*,*migrations*,*admin*,*.jinja,*dashboard*,*settings*,*wsgi*,*questions*,*documents*,*setup.py,*__init__.py,*versiontools_support.py' -m pytest -s --no-migrations ./taiga-contrib-inps -v --tb=native
coverage report
