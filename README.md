# Deploying Django with Docker Compose

This is the finished source code for the tutorial [Deploying Django with Docker Compose](https://londonappdeveloper.com/deploying-django-with-docker-compose/).

In this tutorial, we teach you how to prepare and deploying a Django project to an AWS EC2 instance using Docker Compose.

## links
tutorial video: `https://www.youtube.com/watch?v=mScd-Pc_pX0`

## start app locally for development
`cd Documents/terry/projects/deploy-django-with-docker-compose`
`docker-compose down --volumes --remove-orphans` basically a reset
`docker-compose build`
`docker-compose up`
`docker-compose run --rm app sh -c "python manage.py createsuperuser"`
go to `http://127.0.0.1:8000/admin/`

## start app locally for production testing
`cd Documents/terry/projects/deploy-django-with-docker-compose`
`docker-compose -f docker-compose-deploy.yml down --volumes --remove-orphans`
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
e.g. ALLOWED_HOSTS=Public_IPv4_DNS,hostname2,hostname3
`docker-compose -f docker-compose-deploy.yml up -d`
`docker-compose -f docker-compose-deploy.yml run --rm app sh -c "python manage.py createsuperuser"`
### updating deployed app
commit changes to github, rebuild the image, create and start the container.
`git pull origin`
`docker-compose -f docker-compose-deploy.yml down --volumes` shouldn't need to use this. be careful, this --volumes will clear the database.
`docker-compose -f docker-compose-deploy.yml build`
`docker-compose -f docker-compose-deploy.yml up --no-deps -d` replace with new version but not affect any dependencies

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


