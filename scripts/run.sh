#!/bin/sh

set -e

ls -la /vol/
ls -la /vol/web

whoami

python manage.py wait_for_db
# collect all the static files that are used for each app and put them in the same place. This place/location is
# stated in settings.py 'STATIC_ROOT'. --noinput as you will not be able to answer.
python manage.py collectstatic --noinput
# run migrations if there are any
python manage.py migrate

# run the uWSGI service
# --socket: 9000 - run it on a socket on port 9000. the socket is the type of connection nginx can make to uWSGI so it can serve the application.
# --workers: uWSGI services can be split into multiple workers. Workers are concurrent workers that can accept requests. too many workers per container
#   can make it crash.
# --master: run it as the master daemon (runs in the foreground)
# --enable-threads: enables multi-threading in the application.
# --module app.wsgi: run the wsgi model that is provided byt he django command. this file is automatically created by django to allow it to be 
#   run as a uWSGI service.
uwsgi --socket :9000 --workers 4 --master --enable-threads --module app.wsgi
