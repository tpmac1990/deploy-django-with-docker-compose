# Deploying Django with Docker Compose

This is the finished source code for the tutorial [Deploying Django with Docker Compose](https://londonappdeveloper.com/deploying-django-with-docker-compose/).

In this tutorial, we teach you how to prepare and deploying a Django project to an AWS EC2 instance using Docker Compose.


## start app locally for development
`cd Documents/terry/projects/deploy-django-with-docker-compose`
`docker-compose build`
`docker-compose up`
`docker-compose run --rm app sh -c "python manage.py createsuperuser"`
go to `http://127.0.0.1:8000/admin/`

## start app locally for production testing
`cd Documents/terry/projects/deploy-django-with-docker-compose`
`docker-compose -f docker-compose-deploy.yml down --volumes`
`docker-compose -f docker-compose-deploy.yml build`
`docker-compose -f docker-compose-deploy.yml up` add `-d` to the end to run in the background
`docker-compose -f docker-compose-deploy.yml run --rm app sh -c "python manage.py createsuperuser"`
go to `http://127.0.0.1/admin/`

## start app in ec2 instance
`cd documents/terry/keypairs`
`ssh -i mac_ec2.pem ec2-user@Public_IPv4_address`
`git clone https://github.com/tpmac1990/deploy-django-with-docker-compose.git`
`cd deploy-django-with-docker-compose`
`nano .env`
DB_NAME=app   
DB_USER=approotuser
DB_PASS=superpassword123
SECRET_KEY=secretkey12gh
ALLOWED_HOSTS=Public_IPv4_DNS,hostname2,hostname3

`docker-compose -f docker-compose-deploy.yml up -d`
`docker-compose -f docker-compose-deploy.yml run --rm app sh -c "python manage.py createsuperuser"`

### updating deployed app
commit changes to github
`git pull origin`
`docker-compose -f docker-compose-deploy.yml build app` app is the name of the service
`docker-compose -f docker-compose-deploy.yml up --no-deps -d app` replace app with new version but not affect any dependencies

### docker commands
logs: `docker-compose -f docker-compose-deploy.yml logs`
list all containers: `docker ps -a`
re-attach container: `docker attach <id>`
stop container by id: `docker stop <id>`
all local images: `docker images`
create + start image: `docker run image_id`
running container status: `docker ps`
start a stopped container: `docker start image_id`
pull an image from docker compose: `docker pull image_id`
delete an image: `docker image rm image_id`


## links
Tutorial video: https://www.youtube.com/watch?v=mScd-Pc_pX0
tutorial repo: https://github.com/LondonAppDeveloper/deploy-django-with-docker-compose
my repo: https://github.com/tpmac1990/deploy-django-with-docker-compose


## start project
build the image: `docker-compose build`
create new django project: `docker-compose run --rm app sh -c "django-admin startproject app ."`

1. docker-compose run: this creates a new container out of the image we built
2. --rm app: run the 'app' service that was defined in docker-compose file
3. sh -c "django-admin startproject app .": runs the command 'django-admin startproject app .'. This will 
    create a new django project and call it 'app' and place it in the current directory.

create app: `docker-compose run --rm app sh -c "python manage.py startapp core"`

`docker-compose -f docker-compose-deploy.yml down --volumes`
-f docker-compose-deploy.yml: specify the file if not the default 'docker-compose.yml
down --volumes: clears everything including the volumes. We might have some conflicting volumes from our docker-compose file, 
    so this makes sure it is cleared out so there are no issues. Running this in production will clear the database

`docker-compose -f docker-compose-deploy.yml build` to build the docker images

`docker-compose -f docker-compose-deploy.yml up` start our docker images/services in the deployment mode. This is a simulation
of what will be running on the deployment server

`docker-compose -f docker-compose-deploy.yml run --rm app sh -c "python manage.py createsuperuser"` create superuser on deployed server


## Notes
- environment variables (os.environ.get('')) are stored in the docker-compose.yml file
- run 'docker-compose build' after changes are made to any file which 'docker-compose.yml' depends on e.g. 'requirements.txt' 
- need to create a wait for db command so the app will not start before the db is up and running app/core/management/commands/wait_for_db.py


## Reverse proxy setup
configure application to handle static and media files
uWSGI - web service gateway interface
this takes requests from the internet such as http requests and passes and runs them as python code. 
so it is really good at running python code, however it doesn't serve static files very well.
django/python can run these files, but it is not recommended to do that when deploying the application
as it is very inefficient.
A reverse proxy should be used such as apache or NGINX. This is a proxy container that sites in-front of 
of the application. Use NGINX as it has good documentation and works well with uWSGI.
A reverse proxy serves URLs starting with /static from the disk and forwards the rest to the app container.
this is the recommended setup in the django documentation
We need to configure our django project to store the static files in the correct place and then configure
docker to map these volumes and then create and nginx proxy.

## proxy directory (uwsgi_params)
This is used to store the docker configuration for our reverse proxy that we are going to create with nginx. Read above on why we need a
reverse proxy. 
uwsgi_params: holds a predefined list of headers that map to the different requests that are sent to the WSGI server.
`https://uwsgi-docs.readthedocs.io/en/latest/Nginx.html#what-is-the-uwsgi-params-file`
This is useful when forwarding requests because if you ever need to access any of the request headers in django, you want to get the 
request headers that were made on the actual request to the proxy and not the one that the proxy made to the app. e.g. if you were trying to 
get the remote address which is the computer that is connecting to you django app. by default, if you didn't have this it would give you the 
address of the proxy and not the address of the user. So we define the list so the header values can be forwarded to the WSGI service.
default.conf.tpl: this is the nginx configuration file that we're going to setup so nginx knows how to handle our requests.

${LISTEN_PORT}:  environment variable. There is a script that pull these in for us when we start our proxy.

server {
    # listen on the port specified e.g.(8000/8080)
    listen ${LISTEN_PORT};

    # create a location block to catch any urls that start with '/static/' and they will be forwarded to '/vol/static'
    # so when we run our proxy we can map this volume to the same volume on our app container so all the static and media files 
    # are shared and accessible between the proxy and the app and this allows us to basically forward any request that starts with 
    # static to this directory. Inside this directory we will have another static directory and a media directory so the rest of the url gets 
    # gets trimmed off and appended to '/static'. In settings.py we have '/static/static' & '/static/media' so we only have to create one location
    # to manage both.
    location /static {
        alias /vol/static;
    }

    # this location block will catch everything that wasn't caught by the first. This is the block we want to forward to out WSGI service.
    location / {
        # pass the request to the uWSGI pass service which connects to the app host and the app port that is specified in the configuration.
        uwsgi_pass              ${APP_HOST}:${APP_PORT};
        # include the uWSGI params file. when we create the docker file we copy the location of that file to this location here.
        include                 /etc/nginx/uwsgi_params;
        # set to 10 megabytes. This sets the maximum size of the request that can be sent to the proxy to 10M.
        client_max_body_size    10M;
    }
}

run.sh: script to run our proxy server

Dockerfile: this is just the Dockerfile for the proxy, not the app.

scripts/run.sh: Configure django app to run as a uWSGI service



## Tutorial sections
00:00:00 - Introduction 
00:01:22 - Requirements
00:02:26 - Creating a new project on Github 
00:04:22 - Setup Docker in our project
00:14:50 - Create a Docker Compose file for running development server
00:18:42 - Create a .dockerignore file
00:22:33 - Update settings.py file so that it pulls configuration values from environment variables 
00:30:04 - Add a database to use for our application 
00:33:55 - Add the Postgres driver to our Django application 
00:41:05 - Create a model that we can test with in Django  
00:41:14 - Create a new app in our Django project to add the model to
00:48:35 - Add a wait for db command
00:56:34 - Update Docker Compose file to handle migrations and run this command before we start the app
00:59:37 - Configure our application to handle static and media files
01:02:00 - Configure our application to handle these static and media  files
01:06:20 - Update settings.py to configure the locations that we created for static and media files 
01:10:37 - Test our local development server
01:15:35 - Adding the uWSGI_params file 
01:24:20 - Start the NGINX server
01:25:08 - Create a Docker file inside our proxy 
01:27:42 - Define default environment variables 
01:33:12 - Configure our Django app to run as a uWSGI service
01:59:40 - Test to ensure we can upload images in production mode 
02:01:51 - Deploy to an AWS server 
02:04:46 - Create a virtual machine 
02:09:48 - Installing Git
02:12:49 - Update project code and push to Github
02:13:00 - Set up a deploy key 
02:17:01 - Clone and run the service 
02:18:07 - Add the configuration 
02:19:56 - Launch our application 
02:21:16 - Create a superuser to test with