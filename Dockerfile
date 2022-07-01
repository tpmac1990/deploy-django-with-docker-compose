# get from https://hub.docker.com/_/python?tab=tags&page=1&name=alpine
# I couldn't find the exact version below, but I used it anyway to be consistent
FROM python:3.9-alpine3.13
# define the author of the generated images. stored in metadata. can be viewed with command 'docker inspect'
LABEL maintainer="londonappdeveloper.com"

# print outputs from the application to the console
ENV PYTHONUNBUFFERED 1

# copy the current files to the image
COPY ./requirements.txt /requirements.txt
COPY ./app /app
COPY ./scripts /scripts

# set the working directory of the container. basically runs 'cd /app'
WORKDIR /app
# expose the port we will use when connecting to the django development server
EXPOSE 8000

# RUN: runs a command when building the image. put it all on one line as docker will create a new image layer
#   for each run comand. Hence, reduce the layers and keep the image as light weight as possible.
#   separate lines with '&& \'
# python -m venv /py: create a virtual environment inside the image for storing the python dependencies. Not necessary, but it does
#   separate project specific and apline image dependencies (even though there shouldn't be any on the alpine base image)
# /py/bin/pip install --upgrade pip: install pip. need to specify the full path to the pip executable inside the py environment. We do that as it 
#   hasn't been added to the system path yet. so if we did 'pip install --upgrade pip' it would upgrade pip on the version of pip outside the
#   version environment.
# apk add --update --no-cache postgresql-client: installs the postgres client and everything postgresql driver needs in order to connect to the 
#   postgres server
# apk add --update --no-cache --virtual .tmp-deps build-base postgresql-dev musl-dev linux-headers: connects postgres
#   .tmp-deps: everything installed in the .tmp-deps is only required to install the driver and can be removed on completion to keep the image light weight.
#   apk: apline package manager and is what you use to install packages on the apline docker images.
#   --update: update the package repo for this specified dependencies.
#   --no-cache: no caching
#   linux-headers: required for the installation of uWSGI
# apk del .tmp-deps: delete the temoporary dependencies
# /py/bin/pip install -r /requirements.txt: install all requirements. 'psycopg2' is the driver used to connect to postgres.
# adduser --disabled-password --no-create-home app: add a user. 'app' is the name of the user. this is the user that will be running our app in the 
#   container. without this line, the app will run as the root user. this is not recommended as if someone was to compromise your application then 
#   they will have full access to everything in that container. when adding it as an unpriveliged user such as 'app' then if a user does compromise
#   the appilication, then they will only have access to what the 'app' user has access to. simply, it is a security precaution.
#   --disabled-password: no password required for the user
#   --no-create-home: don't create a home for the user as it's not required
# mkdir -p /vol/web/static: create a directory to hold static files e.g. css, js
#   -p: create any subdirectories that are requuired
# mkdir -p /vol/web/media: create a media directory to hold all media files users upload when the application is running e.g. attachment, profile pic
# chown -R app:app /vol: 
#   chown: changes ownership of the file. by default the files will be owned by the root user, but we need them to be owned by the application user
#       so it has permission to add and make changes to these files.
#   -R: recursive, so will will change ownership of the entire tree
# chmod -R 755 /vol: permissions, we need the owner to have read, write permissions in that directory
# chmod -R +x /scripts: makes all scripts in scripts directory executable.
RUN python -m venv /py && \ 
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-deps \
        build-base postgresql-dev musl-dev linux-headers && \
    /py/bin/pip install -r /requirements.txt && \
    apk del .tmp-deps && \
    adduser --disabled-password --no-create-home app && \
    mkdir -p /vol/web/static && \
    mkdir -p /vol/web/media && \
    chown -R app:app /vol && \
    chmod -R 755 /vol && \
    chmod -R +x /scripts

# add our virtual environment to our system path. so running a python command it will automatically use python inside out virtual environment and not the 
#   the version of python on the alpine image.
# add /scripts to path so the full path isn't required to run the scripts
ENV PATH="/scripts:/py/bin:$PATH"

# switch the user from the root user to the app user that we created above. Everything run after this line will be run as the 'app' user
USER app

# run the scripts as the default command
CMD ["run.sh"]
