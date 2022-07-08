### summary
This is a wagtail app boiler plate. To run:
`cd app`
`docker build -t app .`


## scapes
setup wagtail with docker: https://learnwagtail.com/tutorials/how-install-wagtail-docker/
- I created a virtualenv to create wagtail first, thenstarted a docker container

basic commands:
pip3 install virtualenv
export PATH=$PATH:~/Library/Python/3.8/bin
virtualenv venv    
source venv/bin/activate
pip install wagtail
wagtail start app
source deactivate
delete /venv
docker build -t app . 
docker run -p 8000:8000 app
- in new terminal
docker container ls - get id of container
docker exec -it <container-id> /bin/bash
./manage.py createsuperuser
./manage.py runserver 0.0.0.0:8000


create image: docker build -t app .
list all images: docker images 
delete all images: docker system prune -a
list all containers: docker container ls
stop container: docker stop id
step into container: docker exec -it <container_id> /bin/bash
