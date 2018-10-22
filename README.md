# todobackend
from pluralsight CI with Docker and Ansible

==============================================================
Section 1 - setting up the Django App to be used in the course:
==============================================================
This course uses Django based app "todobackend" - a list manager - so the first section deals with settiong up this application:

Check python is installed:
  python --version
    Python 2.7.10

Check pip is installed:
  sudo easy_install pip
    
Install Django
  pip install django==1.9

Create Django project
  django-admin startproject todobackend
(this creates a proect in dir "todobackend" with manage.py and a subfolder todobackend (this is the Django root folder) containing __init__.py	settings	urls.py and wsgi.py)

To keep app code separate from CI/CD code move this Django project to a dir "src"
  mkdir src
  mv manage.py src
  mv todobackend/ src
  
  tree src
  src
  ├── manage.py
  ├── todobackend
  │   ├── __init__.py
  │   ├── settings.py
  │   ├── urls.py
  │   ├── wsgi.py

Create a git repo and commit (subsequent commits will not be mentioned - but should be done periodically)
  git init
  git commit -a -m "Initial Commit"
  
Create a python virtual environment (an isolated sandpit where specific versions of packages can be installed)
  virtualalenv venv 
(creates a virtual env called venv)

Add the venv folder to .gitignore so that it doesn't get saved to git
  cat .gitignore
  # Ignore the virtual environment
  venv

Activate the virtual env:
  source venv/bin/activate
Shell prompt indicates we are now in virtual environment:
  (venv) Gareths-MBP:todobackend garethjones$ 

Now update venv with Django and pip as we did for non-venv setup:
  pip install pip --upgrade
  pip install django==1.9

Install some packages required by the app:
  pip install djangorestframework==3.3
  pip install django-cors-headers==1.1

Now start a new Django app called "todo"

  cd src
  python manage.py startapp todo

Add the app to the settings.py and also update settings.py to reference the additional rest-framework and cors-headers packages

Edit the models.py for the app:
  class TodoItem(models.Model):
	title = models.CharField(max_length=256, null=True, blank=True)
	completed = models.BooleanField(blank=True, default=False)
	url = models.CharField(max_length=256, null=True, blank=True)
	order = models.IntegerField(null=True, blank=True)

Make the schema in the Db using Djangos in-built object-relational-mapper:
  python manage.py makemigrations todo
(this can be run periodically to capture model changes in the schema)

Now apply these migrations to the Db:
  python manage.py migrate

By doing this - Django creates an sqlite Db in the project root:
  ls src
    db.sqlite3
Next create serializers:
  cat src/todo/serializers.py
    from rest_framework import serializers
    from todo.models import TodoItem

    class TodoItemSerializer(serializers.HyperlinkedModelSerializer):
	    url = serializers.ReadOnlyField()
	    class Meta:
		    model = TodoItem
		    fields = ('url', 'title', 'completed', 'order')

Next create the views:
  cat src/todo/views.py
  
Next configure routing:
  cat src/todo/urls.py
  cat src/todobackend/urls.py

Now test the application:
  python manage.py runserver
    Starting development server at http://127.0.0.1:8000/
browse to the base url

==============================================================
Section 2 - Unit and Integration testing for the demo app:
==============================================================
Create tests.py

Run the tests using:
  python manage.py test

Refactor settings to use mysql database
To separate settings for test and production, create a settings subfolder with a settings file for each env:
  ls todobackend/settings/
  __init__.py	base.py		release.py	test.py

Edit the manage.py and the wsgi.py files to reflect the new base settings location
Edit the test.py to use a mysql db:
  	'ENGINE': 'django.db.backends.mysql',
		'NAME': os.environ.get('MYSQL_DATABASE', 'todobackend'),
		'USER': os.environ.get('MYSQL_USER', 'todo'),
		'PASSWORD': os.environ.get('MYSQL_PASSWORD', 'password'),
		'HOST': os.environ.get('MYSQL_HOST', 'localhost'),
		'PORT': os.environ.get('MYSQL_PORT', '3306'),

Install MYSQL:
  brew install homebrew/versions/mysql56
  mysql.server start
  mysql_secure_installation
  
Now log into mysql and create user, db and grant user priviliges
  mysql -u root -p
  CREATE DATABASE todobackend;
  GRANT ALL PRIVILEGES ON *.* TO 'todo'@'localhost' identified by 'password';
  quit

Install external mysql python package
  pip install mysql-python

Run the tests using the new settings by specifying a settings flag:
  python manage.py test --settings=todobackend.settings.test

To confirm it is using the new mysql db - stop mysql and retest - it should abend:
  mysql.server stop
  python manage.py test --settings=todobackend.settings.test

To improve the test output - install some external test packages:
  pip install django-nose
  pip install pinocchio
  pip install coverage

Edit test.py to add django_nose to the list of installed apps and a TESTRUNNER setting to specify nose as thenew test runner
  INSTALLED_APPS += ('django_nose', )
  TEST_RUNNER = 'django_nose.NoseTestSuiteRunner'
  TEST_OUTPUT_DIR = os.environ.get('TEST_OUTPUT_DIR','.')
  NOSE_ARGS = [
        '--verbosity=2',
        '--nologcapture',
        '--with-coverage',
        '--cover-package=todo',
        '--with-spec',
        '--spec-color',
        '--with-xunit',
        '--xunit-file=%s/unittests.xml' % TEST_OUTPUT_DIR,
        '--cover-xml',
        '--cover-xml-file=%s/coverage.xml' % TEST_OUTPUT_DIR,
  ]
Deactivate the virtual env
  deactivate
  
==============================================================
Section 3 - Acceptance Testing: 
==============================================================
Install nodejs and mocha:
  cd ~/cd-docker-ansible
  brew install nodejs
create folder todobackend-specs at same level as base todobackend folder
  cd ~/cd-docker-ansible
  mkdir todobackend-specs
Create a git repo
  cd todobackend-specs
  git init
create a gitignore file and and add node_modules to it
  touch .gitignore
  vi .gitignore
    # ignore npm modules
  git commit -a -m "Initial commit"
Create a nodejs project
  npm init
    entry point: app.js
    test command: mocha
Install the required node packages:
  npm install bluebird chai chai-as-promised mocha superagent superagent-promise mocha-jenkins-reporter --save
  
Create tests - create a test.js file in a folder tests
  mkdir test
  vi test/test.js
Run the acceptance tests:
  cd ../todobackend
  source venv/bin/activate
  cd src
Run the migrations
  python manage.py migrate --settings=todobackend.settings.test
Run the server:
  python manage.py runserver --settings=todobackend.settings.test
In a separate window - run the mocha tests:
  cd ~/todobackend-specs/
  node node_modules/.bin/mocha 
(NB - course notes say to run just "mocha" - this doesn't work)

==============================================================
Section 4 - Test the user interface: 
==============================================================
Install the client app created for the course:
  cd ~/cd-docker-ansible/
  git clone https://github.com/jmenga/todobackend-client.git
  cd todobackend-client
  npm install

Start the todobackend-client web server:
  cd todobackend-client/
  node app.js

Browse to http://localhost:3000
Enter the todobackend URL in the input box:
  http://localhost:8000/todos

==============================================================
Section 5 - Unit/Integration testing using Docker: 
==============================================================
The continuous delivery workflow: Test, Build, Release, Deploy
Focus in this module is Test:
  Create Test Environment
    Base Image
    Test Image
    Docker Compose
  Run unit tests        (These are a simpler subset of integration tests so are not covered separately here)
    Single container
  Run integration tests
    Single/Multi container
    Complex workflow

Recommended approach - create a Base image for each application which establishes:
    Minimum runtime environment - minimum to increase performance and decrease attack surface
    Application dependencies
    System Configuration
    Default settings
 
Application then gets installed into a Release image - Release image is a child of the Base image so Release image contains the runtime required for the application
Tasks for Creating the Release consist of:
  Install Application
  Application Configuration
  Application entrypoint

This approach promotes re-usability and gives a separation of concerns eg:
  Ops team can own base image and can therefore apply OS and security patches as required (etc)
  Dev teams can create and own Release images

This heirachy means Development images can be created as children of Base image- Dev image will by defaukt have the app runtime so can have dev dependencies and test/build tooling added. Dev images are used in Test, Build and Release phases to create application release artifacts that are then deployed to Release images.


Common approach is to take a base image from Docker Official Repositories, then have a separate base image depending on technology eg one for java, one for python etc


==============================================================
Section 6 - Creating the base image: 
==============================================================

  - Initial setup: Base image will be maintained in separate repository outside of the main application
  - Choose parent image
  - Describe OS packages and dependencies
  - establish virtual environment (for python) and an entrypoint for the app
  - Build and test the base image
  
First step create new folders for todobackend image (separate to application for separation of concerns as previously described), create git repo and create a Dockerfile :
    mkdir ~/cd-docker-ansible/todobackend-base
    cd ~/cd-docker-ansible/todobackend-base
    git init
    touch Dockerfile
  
  Dockerfile will be based on Dockers Ubuntu image with some basic setup for local images :
  
    cat Dockerfile 
  FROM ubuntu:trusty
  MAINTAINER Gareth Jones <gareth_jones76@hotmail.com>
  ENV TERM=xterm-256color
  RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list

Base image will need to support python so add these lines to Dockerfile:
  RUN apt-get update && \
    apt-get install -qy \
    -o APT::Install-Recommend=false -o APT::Install-Suggests=false \
    python python-virtualenv 

The -o option specify that recommended and suggested packages are NOT installed - only requested packages are installed, keeping our image minimal, fast and more secure
The last line installs the python virtual env package, the pytho runtime and the python mysql interface

Next establish the virtual environment (in a folder called appenv - the "." operator is used rather than the bash "source" command because Docker images are built using the Bourne shell) and upgrade pip (required for access to wheel package later - wheels are python application distribution packages - like ears/wars) - add these lines to the Dockerfile:
  RUN virtualenv /appenv && \
    . /appenv/bin/activate && \
    pip install pip --upgrade

Previously we activated the venv and the ran a command. The Docker image needs an entrypoint that does both of these. We create an entrypoint script to do this in scripts/entrypoint.sh and then add it to the base image under /usr/local/bin (which is in the default path) so that it is available to the base image. We also reset the perms and set it as the entrypoint so any container invoked from the image will run this entrypoint script by default.
Add these lines to the Dockerfile:
  ADD scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
  RUN chmod +x /usr/local/bin/entrypoint.sh
  ENTRYPOINT ["entrypoint.sh"]

Create the entrypoint script:
  mkdir scripts
  vi scripts/entrypoint.sh
    #!/bin/bash
    . /appenv/bin/activate
    exec $@
This script activates a venv and then relinquishes command to the recieved argument without creating a new process (so that it runs within the venv)
Using "exec" is important because the recieved command (eg entrypoint.sh python manage.sh test) becomes PID 1. Stop commands sent to the docker image will be passed to the application for a clean stop. If "exec" is not used the application process becomes a child PID and bash remains the parent process. Stop commands go to bash but not to the application - so dockers "kills" them so the app is not allowed to stop gracefully.

Next build the docker image using the build command (with a tag to identify it - in this case gjones/todobackend-base):
  docker build -t gjones/todobackend-base .

Check the image has been created and tagged:
  docker images
    REPOSITORY                              TAG                      IMAGE ID            CREATED              SIZE
    gjones/todobackend-base                 latest                   6c937ed08209        About a minute ago   412MB
    ubuntu                                  trusty                   d6ed29ffda6b        11 months ago        221MB

To demo the importance of using "exec" try running the image passing it the "ps" command - this will create an image from the gjones/todobackend-base container and run the ps command as PID1 (By default a container’s file system persists even after the container exits. This makes debugging a lot easier since you can inspect the final state and you retain all your data by default. But if you are running short-term foreground processes, these container file systems can really pile up. For Docker to automatically clean up the container and remove the file system when the container exits add the --rm flag):
  docker run --rm gjones/todobackend-base ps
      PID TTY          TIME CMD
      1 ?        00:00:00 ps

Now vi the entrypoint script to remove the "exec", rebuild and retry:
docker build -t gjones/todobackend-base .
docker run --rm gjones/todobackend-base ps
  PID TTY          TIME CMD
    1 ?        00:00:00 entrypoint.sh
   13 ?        00:00:00 ps
 Note the ps command is no longer PID1 - so terminating the container will not cleanly terminate the child process.
 

==============================================================
Section 7 - Creating the development image: 
==============================================================
Steps are:
  Build the Dev image
  Change App to create application requirement files - (add 3rd party python libs)
  Test the dev image
  Iterate to reduce testing time
  Test with differnet test settings

Development image is used for Continuous Delivery workflow - it never gets published but gets built dynamically each time the workflow is invoked.
So unlike the Base image, the Development image Dockerfile can be stored in the application repository with the main app
  cd ~/cd-docker-ansible/todobackend
  mkdir -p docker/dev
  touch docker/dev/Dockerfile

Edit the Docker file:
Development image is a child of the Base image and should use the latest version of the base image 
  FROM garethjones76/todobackend-base:latest
  MAINTAINER Gareth Jones <gareth_jones76@gmail.com>
  
Development image has 2 purposes:
1) For running unit and integration tests
2) To build the application artefacts
So it needs the python-dev libraries so that it can compile python code from source. It also needs thelibmysqlclient-dev package so that pip install can access the mysql install headers:
  
  # Install dev/build dependencies
  RUN apt-get update && \
    apt-get install -qy python-dev libmysqlclient-dev
  
Next establish the virtual environment and install wheel package 
  # Activate virtual environment and install wheel support
  RUN . /appenv/bin/activate && \
    pip install wheel --upgrade

Add environment variables to define Wheel output dir and cache location
  # PIP environment variables (NOTE: must be set after installing wheel)
  ENV WHEELHOUSE=/wheelhouse PIP_WHEEL_DIR=/wheelhouse PIP_FIND_LINKS=/wheelhouse XDG_CACHE_HOME=/cache

Add two volumes - for wheel files, test reports :
  # OUTPUT: Build artefacts (Wheels) are output here
  VOLUME /wheelhouse
  # OUTPUT: Test reports are output here
  VOLUME /reports

Add a new entrypoint script test.sh:
  # Add test entrypoint script
  COPY scripts/test.sh /usr/local/bin/test.sh
  RUN chmod +x /usr/local/bin/test.sh

The test.sh is similar to the original entrypoint.sh but also imports some required python packages
Over-ride the entrypoint defined in the Base Dockerfile. Also define a default command for the entrypoint:
  # Set defaults for entrypoint and command string
  ENTRYPOINT ["test.sh"]
  CMD ["python", "manage.py", "test", "--noinput"]

Copy the application code from src in our repository to /application in the image and set the working directory to be /application:
  # Add application source
  COPY src /application
  WORKDIR /application

Secifying these two directives last is important - the application is the element which will change most so having them last means much of the image will be cached allowing for reuse and a faster build process each time the workflow is run.

Define the test.sh entrypoint script:
  #!/bin/bash
  # Activate virtual environment
  . /appenv/bin/activate
  # Install application test requirements
  pip install -r requirements_test.txt
  # Run test.sh arguments
  exec $@

The test.sh file specifies the python requirements in src/requirements.txt or src/requirements_test.txt  (and imports them using the -r flag). The format of the requirements file is to have the last part of the "pip install xxx" command. Each pip install xxx command is executed in the order specified.
Having multiple requirements files allows for imports for the base to be different to the test requirements. The initial requirements file can be generated from a virtual env using the pip freeze command:
  source venv/bin/activate
  cd src
  pip freeze > requirements.txt
  cat requirements.txt
    colorama==0.3.9
    coverage==4.4.2
    Django==1.9
    django-cors-headers==1.1.0
    django-nose==1.4.5
    djangorestframework==3.3.0
    MySQL-python==1.2.5
    nose==1.3.7
    pinocchio==0.4.2

This outputs all of the application requirements so we have to separate out Base requirements from Dev requirements
The django and mysql packages are required by the base build - the other lines are required for testing so move them to the src/requirements_test.txt file (note the requirements_test.txt also includes the contents of requirements.txt using the "-r" flag).
  cat requirements_test.txt
    -r requirements.txt
    colorama==0.3.9
    coverage==4.4.2
    nose==1.3.7
    pinocchio==0.4.2
    
  cat requirements.txt
    Django==1.9
    django-cors-headers==1.1.0
    django-nose==1.4.5
    djangorestframework==3.3.0
    MySQL-python==1.2.5

Add a .dockerignore file to omit the contents of the venv:
  cat .dockerignore 
    venv
Now build the Dev image (this wont be published - Dev image gets built each time the workflow is run)
  docker build -t todobackend-dev -f docker/dev/Dockerfile .
  
==============================================================
Section 8 - Reducing testing time: 
==============================================================
The run takes > 40secs (for a very simple application) :
  time docker run --rm todobackend-dev
  ...
  ...
  Ran 12 tests in 0.116s

  OK
  Creating test database for alias 'default'...
  System check identified no issues (0 silenced).
  Destroying test database for alias 'default'...

  real	0m45.908s
  user	0m0.101s
  sys	0m0.127s

because the container is dwonloading each dependency in the requirements file from the internet :  
  Collecting Django==1.11 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting django-cors-headers>=1.1.0 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting djangorestframework>=3.3.1 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting MySQL-python>=1.2.5 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting uwsgi>=2.0 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting colorama>=0.3.3 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting coverage>=4.0.3 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting django-nose>=1.4.2 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting nose>=1.3.7 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting pinocchio>=0.4.2 (from todobackend==0.1.0->-r requirements_test.txt (line 1))
  Collecting pytz (from Django==1.11->todobackend==0.1.0->-r requirements_test.txt (line 1))
  
It is storing them in the cache but not resusing the cache from the revious run because each time the container finishes the cache is destroyed  :
  Building wheels for collected packages: MySQL-python, uwsgi, pinocchio
  Running setup.py bdist_wheel for MySQL-python: started
  Running setup.py bdist_wheel for MySQL-python: finished with status 'done'
  Stored in directory: /cache/pip/wheels/16/ed/55/f27783bb5ab1cb57c9ac00356859d19adf17d76c31230f3f1f
  Running setup.py bdist_wheel for uwsgi: started
  Running setup.py bdist_wheel for uwsgi: finished with status 'done'
  Stored in directory: /cache/pip/wheels/81/ce/dc/c99ec47f2391f6b1e1f66f062d9224e8d799eadb2849c564ef
  Running setup.py bdist_wheel for pinocchio: started
  Running setup.py bdist_wheel for pinocchio: finished with status 'done'
  Stored in directory: /cache/pip/wheels/ab/43/84/ba075171b712e03d94d14b1e264a80678dbca7ebb8bfe4f7b3

To persist the cache folder between runs we can create a "volume container" (a container that can share its volumes with other containers). Volumes in the volume container can be mapped to a physical path on the docker host eg /cache in the Dev build can map to /cache in the Volume container which can map to /tmp/cache on the host. Mapping to the underlying host means that the volume container can be destroyed but will recreate its cache from the underlying mapped directory. :

Creating the Volume container:
  docker run -v /tmp/cache:/cache --entrypoint true --name cache todobackend-dev

This maps /tmp/cache on the host to /cache in the container. The "--entrypoint true" option means that the container immediately exits without doing anything. The container is named cache.  And the container is created from the todobackend-dev image so that all user,group and folder permissions are consistent.

Now try running again with the cache volume specified:
  time docker run --rm --volumes-from cache todobackend-dev

1st time timings look same:
  Ran 12 tests in 0.119s
  OK
  ...
  real	0m48.654s
  user	0m0.100s
  sys	0m0.148s

Subsequent runs are faster as they can now access the cache:
  Ran 12 tests in 0.109s
  OK
  ...
  real	0m10.773s
  user	0m0.090s
  sys	0m0.140s


==============================================================
Section 9 - Using Docker Compose : 
==============================================================
The tests have so far been done using the django default settings. To run using the specific settings added to the test.py file in the previous steps - add an environment variable to the run command to define the django settings module environment variable:
	docker run --rm -e DJANGO_SETTINGS_MODULE=todobackend.settings.test --volumes-from cache todobackend-dev
This point the runtime at the file:
	../todobackend/src/todobackend/settings/test.py
However this contains the lines:
	DATABASES = {
	
	'default': {
		'ENGINE': 'django.db.backends.mysql',
		'NAME': os.environ.get('MYSQL_DATABASE', 'todobackend'),
		'USER': os.environ.get('MYSQL_USER', 'todo'),
		'PASSWORD': os.environ.get('MYSQL_PASSWORD', 'password'),
		'HOST': os.environ.get('MYSQL_HOST', 'localhost'),
but 'HOST': os.environ.get('MYSQL_HOST', 'localhost'), will fail because mysql is not running in the docker container but on the docker host. 
Running mysql in the container would break the golden rule "one process per container". We could point to the mysql server on the host but this breaks portability. The answer is to run a separate container for mysql and to link the two. The best way to define multiple containers is using Docker Compose which is a tool for defining and running multi-container Docker applications.

Next steps are to create a Docker Compose definition and run the tests using the docker compose config with configuration to allow for mysql to successfully start before testing.

First create the docker-compose.yml file:
	vi ~/cd-docker-ansible/todobackend/docker/dev/docker-compose.yml
	
This file contains "service" definitions - each of which corresponds to a docker container. The service defintion defines items such as the image to use (or alternatively what to build), linked containers, volumes, volume containers, environment variables etc

The compose file for this app can be described as follows :

	test:
  		build: ../../
  		dockerfile: docker/dev/Dockerfile
  		volumes_from:
    		  - cache
  		links:
  		  - db
  		environment:
    		  DJANGO_SETTINGS_MODULE: todobackend.settings.test
    	 	  MYSQL_HOST: db
    		  MYSQL_USER: root
    		  MYSQL_PASSWORD: password
    		  TEST_OUTPUT_DIR: /reports
This is the application service named "test". 
Because the Dev env is built each iteration, this uses a build: rather than an image: option. The build: option defines the context for creating the app ie the top-level root folder for the app repository - in this case the root folder is "todobackend" which is reached from the docker-compose file via ../../ 
Next is the dockerfile to be used in the build - specified relative to the build: context 
Next volumes are defined using the volumes-from: option - this defines a volume "cache". This will look for a container named cache or alternaively a service in the docker-compose file name cache to create.
Next the links: option is used to define other services to which this service requires a link - in this case "db". This means an entry "db" will be automatically added to /etc/hosts in the "test" container pointing to the "db" container.
Next the environment settings are defined - note they include the "MYSQL_HOST: db" setting plus its user and password. They also include the "TEST_OUTPUT_DIR: /reports" variable which is specified as a volume in the development image.


Next we define our cache: service
	cache:
  		build: ../../
  		dockerfile: docker/dev/Dockerfile
  		volumes:
    		  - /tmp/cache:/cache
  		entrypoint: "true"

These service settings mirror exactly what we previously did from the command line. This also gets built using the Dev Dockerfile. This maps the host dir "/tmp/cache" to the container dir "/build" and sets "entrypoint: true" so that the container exits without doing anything.

We also add a db: service to define the container running mysql for testing:
	db:
  		image: mysql:5.6
  		hostname: db
  		expose:
    		  - "3306"
  		environment:
    		  MYSQL_ROOT_PASSWORD: password

This service exposes port 3306 - the default mysql port
It also defines root password - which matches the root password defined in the "test:" service

We can now test this integrated environment we have defined. This next command will use the docker-compose.yml definition to bring up an environment called test:

	cd ~/cd-docker-ansible/todobackend/docker/dev
	docker-compose up test


To see the running services we can use :
	docker-compose up test
		   Name                  Command               State     Ports  
		----------------------------------------------------------------
		dev_cache_1   true                             Exit 0           
		dev_db_1      docker-entrypoint.sh mysqld      Up       3306/tcp
		dev_test_1    test.sh python manage.py t ...   Exit 0           
This shows the db is still running

To view the logs on the running db service we can use:
	docker-compose logs db
To kill the services and force clear the caches use:
	docker-compose kill
	docker-compose rm -f
	
Although there is a link between services test: and db:, docker-compose will not wait for mysql on the db: container to initialise. So there is a race condition - tests could run before the mysql db initialises and might therefore fail. 
To resolve this race condition we need to have test: wait for db: to complete it startup. To do this we create an agent service using ansible. 
In a folder named docker-ansible - create a docker image to run ansible:
	cd ~/cd-docker-ansible/
	mkdir docker-ansible
	vi docker-ansible/Dockerfile

This Dockerfile creates an ubuntu container, installs ansible, creates an ansible volume then runs an ansible workbook with a default value of site.yml:
	FROM ubuntu:trusty
	MAINTAINER GarethJones <gareth_jones76@hotmail.com>

	ENV TERM=xterm-256color

	RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list

	RUN apt-get update -qy && \
	    apt-get install -qy software-properties-common && \
	    apt-add-repository -y ppa:ansible/ansible && \
	    apt-get update -qy && \
	    apt-get install -qy ansible

	COPY ansible /ansible

	VOLUME /ansible
	WORKDIR /ansible
	
	ENTRYPOINT ["ansible-playbook"]
	CMD ["site.yml"]

Next in the ~/cd-docker-ansible/todobackend folder create a folder named ansible and add a yml file name probe.yml:
	cat probe.yml 
	---
	- name: Probe Host
	  hosts: localhost
	  connection: local
	  gather_facts: no
	  tasks:
	  - name: Set facts
	    set_fact:
	      probe_host: "{{ lookup('env','PROBE_HOST') }}"
	      probe_port: "{{ lookup('env','PROBE_PORT') }}"
	      probe_delay: "{{ lookup('env','PROBE_DELAY') | default(0, true) }}"
	      probe_timeout: "{{ lookup('env','PROBE_TIMEOUT') | default (180, true) }}"
	  - name: Message
	    debug: 
	      msg: >
	        Probing {{ probe_host }}:{{ probe_port }} with delay={{ probe_delay }}s
	        and timeout={{ probe_timeout}}s
	  - name: Waiting for host to respond...
	    local_action: >
	      wait_for host={{ probe_host }}
	      port={{ probe_port }}
	      delay={{ probe_delay }}
	      timeout={{ probe_timeout }}

The probe.yml runs locally, and does 3 tasks - set some variables from env variables (which must be set as they have no default values), print a message, then wait until a tcp connection is made to the host/port specified

We add the agent service to the docker compose file ~/cd-docker-ansible/todobackend/docker/dev/docker-compose.yml:
	
	agent:
	  image: garethjones76/ansible
	  volumes:
    	    - ../../ansible/probe.yml:/ansible/site.yml
	  links:
	    - db
	  environment:
	    PROBE_HOST: "db"
	    PROBE_PORT: "3306"
	  command: ["probe.yml"]

This uses the ansible image we just specified (ie this service uses image: not build: ) and maps the probe.yml file we created to /ansible/site.yml 

==============================================================
Section 10 - Creating releases using docker:  
==============================================================
Next step in CI after Test is to Build.
Here we take tested application and build deployable, versioned application artefacts - in this case Python Wheels.
We need to add metadata to the app to describe the Wheel and add a builder service to the docker-compose definition

Step 1- We create build enviroment with necessary dev dependencies and build tooling for building the app (reusing the Dev environment created for the Test stage). 
Step 2 - We add a builder service to the environment which compiles the application to create Wheel artefact.
Step 3 - we publish the Wheel artefact - at a MINIMUM it needs to be published locally to a folder and made available for release stage.

Two types of app artefact :
	- Source distribution == source + metedata in a deployable archive. Code needs to be extracted and compiled after distribution. 	  Good for dev environments but not Prod as we dont want build tools in prod env and we want to resolve all build dependencies 		  before deploying to Prod
	- Built distribution - Build the app and package up the binary output. This is best for Prod environments

Building the app consists of several steps	;
	- add package metadata
	- test the build 
	- add the build service to create pyhon wheels
	- publish the wheel

Add package metadata - this metadata describes the app name, version, structure, dependencies - everything required to build it. For python the universal standard for build metadata is to place it in a file named setup.py:
	vi ~/cd-docker-ansible/todobackend/src/setup.py
		from setuptools import setup, find_packages

		setup (
  		name                 = "todobackend",
  		version              = "0.1.0",
  		description          = "Todobackend Django REST service",
  		packages             = find_packages(),
  		include_package_data = True,
  		scripts              = ["manage.py"],
  		#install_requires     = ["Django==1.11",
  		install_requires     = ["Django>=1.11.15",
  		                        "django-cors-headers>=1.1.0",
  		                        "djangorestframework>=3.3.1",
  		                        "MySQL-python>=1.2.5",
  		                        "uwsgi>=2.0"],
  		extras_require       = {
  		                          "test": [
  		                            "colorama>=0.3.3",
  		                            "coverage>=4.0.3",
  		                            "django-nose>=1.4.2",
  		                            "nose>=1.3.7",
  		                            "pinocchio>=0.4.2"
  		                          ]
  		                       }
		)

rather than specifying our application packages individually - the "packages = find_packages()" function will scan the sub-directories for any folders with an init.py file. This find_packages() function requires "include_package_data = True".
The "scripts = ["manage.py"]," setting is used to include any scripts we want to be available to our deployed app - in this case manage.py.
The "install_requires" settings lists the applications core dependencies - details we put in the requirements.txt file for the dev build.

Note - we can now replace the contents of requirements.txt with ".". This tells pip to run the "pip install ." command - which installs the app requirements from the "install_requires" coda of the setup.py file

The "extras_require" setting allows definition of arrays of additional dependencies - such as the contents of requirements_test.txt.

Note - we can now replace the contents of requirements_test.txt with "-e .[test]". This tells pip install the app extra requirements from the "extras_require" coda of the setup.py file

Note - specifying ">=" in setup.py eg "pinocchio>=0.4.2" means the app requires "pinocchio=0.4.2 or more recent" - so every time we test and build the app the dependencies will get updated. 

Note - a MANIFEST.IN file can also be included for non-application files such as static content - it's not required for this app.

==============================================================
Section 11 - Adding the Build Service: 
==============================================================

Ensuring consistency in the build:
Now that we have defined minimum versions in the setup.py, there is a chance we could test against on version of a dependency then build against another. In which case the built artefact does not represent a true image of the tested application.

We can resolve this by having the test stage download its dependencies to a cached folder. The build stage then uses the cached dependencies rather than downloading them. 

To do this, first we amend the test.sh script to add the pip download command:
	# Download requirements to build cache
	pip download -d /build -r requirements_test.txt --no-input
this will download the contents of requirements.txt to destination /build without installing them. Because we now have a setup.py, pip will also create a copy of our application source code in the /build folder. So the /build folder has a snapshot of source code for the entire app including its dependencies.

We then amend the pip install command in the test.sh file to reference the /build folder rather than downloading dependencies from the internet:
	# Install application test requirements
	pip install --no-index -f /build -r requirements_test.txt

We have to add /build as a volume in our Dockerfile - now has:
	# OUTPUT: Build artefacts (Wheels) are output here
	VOLUME /wheelhouse

	# OUTPUT: Build cache
	VOLUME /build

	# OUTPUT: Test reports are output here
	VOLUME /reports

Add the /build volume to the cache service in the docker-compose.yml which becomes:
	cache:
  	build: ../../
  	dockerfile: docker/dev/Dockerfile
  	volumes:
  	  - /tmp/cache:/cache
  	  - /build
  	entrypoint: "true"

The test Dockerfile create the /build as a volume and the test service mounts the volumes provided by the cache service so the build folder from the test service is now becomes available to the cache service. 

Next we add a builder service to our docker-compose.yml for the build service:
	
	builder:
	  build:  ../../
	  dockerfile: docker/dev/Dockerfile
	  volumes:
	    - ../../target:/wheelhouse
	  volumes_from:
	    - cache
	  entrypoint: "entrypoint.sh"
	  command: ["pip", "wheel", "--no-index", "-f /build", "."]


The builder service needs the same build and runtime dependencies as the test service so uses the same build: and dockerfile: settings as the test: service.
The builder service maps a "wheelhouse" volume to "../../target" on the host. Mappng the cache service means the /build folder containing the app source and dependencies source are also available to the builder: service

Lastly the entrypoint is over-ridden to run the entrypoint.sh script with the command "["pip", "wheel", "--no-index", "-f /build", "."]"
This will run the pip wheel command with no external downloads (--no-index) but using the /build folder (the -f find option). The  "." option tells pip to use the setup.py file in the current working dir - which is /application as specified in the Dockerfile: WORKDIR /application.
Note - the Dockerfile also contains previously added environment variables that the pip wheel command requires:
	ENV WHEELHOUSE=/wheelhouse PIP_WHEEL_DIR=/wheelhouse PIP_FIND_LINKS=/wheelhouse XDG_CACHE_HOME=/cache


Now to test :
	clear our docker compose environment
		cd docker/dev
		docker-compose kill
		docker-compose rm -f
	invoke the agent service (to start the mysql db) and the test service
		docker-compose up agent
		docker-compose up test

Note the dev_test image is not rebuilt :
	docker images
		REPOSITORY                              TAG                      IMAGE ID            CREATED             SIZE
		dev_test                                latest                   c28debc93a93        10 months ago       476MB

because "docker-compose up" always uses cached images if available. 
So we should always do "docker-compose build" before creating a deliverable so that our tests are run against a clean image that includes the latest changes. So the sequence becomes:
		cd docker/dev
		docker-compose kill
		docker-compose rm -f
	invoke the docker compose build
		docker-compose build
		docker images
			REPOSITORY                              TAG                      IMAGE ID            CREATED             SIZE
			dev_test                                latest                   dc251d0fd317        11 seconds ago      480MB
			dev_builder                             latest                   dc251d0fd317        11 seconds ago      480MB
			dev_cache                               latest                   dc251d0fd317        11 seconds ago      480MB
	invoke the agent service (to start the mysql db) and the test service
		docker-compose up agent
		docker-compose up test
	We can now invoke the builder: service confident we will be building against up to date images
		docker-compose up builder
	Note the wheel files being created eg:
		builder_1  | Collecting Django>=1.11.15 (from todobackend==0.1.0)
		builder_1  |   Saved /wheelhouse/Django-1.11.16-py2.py3-none-any.whl

There should ow be a /target folder on the docker host containing wheel files for the app and its dependencies:
	ls ~/cd-docker-ansible//todobackend/target
		Django-1.11.8-py2.py3-none-any.whl
		django_cors_headers-2.1.0-py2.py3-none-any.whl
		MySQL_python-1.2.5-cp27-cp27mu-linux_x86_64.whl
		djangorestframework-3.7.3-py2.py3-none-any.whl
		uWSGI-2.0.15-cp27-cp27mu-linux_x86_64.whl
		pytz-2017.3-py2.py3-none-any.whl
		todobackend-0.1.0-py2-none-any.whl

==============================================================
Section 12 - Creating Releases using Docker: 
==============================================================
In this stage we:
	Build a release image
	Create a release environment
	UAT test (and if required further testing eg load, stress etc) the release

Step 1 - create the release settings that describe how the app will run in prod and create the release environment using docker-compose
Step 2- bootstrap the release environment and start the application
Step 3 - UAT test the app and if successful - publish the release image

Create the application release settings - create release.py alongside the base.py and test.py files we previously created:
	cd ~/cd-docker-ansible//todobackend/src/todobackend/settings/
	vi release.py
		from base import *
		import os

		# Disable debug
		if os.environ.get('DEBUG'):
		  DEBUG = True
		else:
		  DEBUG = False

		# Must be explicitly specified when Debug is disabled
		ALLOWED_HOSTS = [os.environ.get('ALLOWED_HOSTS', '*')]

		# Database settings
		DATABASES = {
		    'default': {
		        'ENGINE': 'django.db.backends.mysql',
		        'NAME': os.environ.get('MYSQL_DATABASE','todobackend'),
		        'USER': os.environ.get('MYSQL_USER','todo'),
		        'PASSWORD': os.environ.get('MYSQL_PASSWORD','password'),
		        'HOST': os.environ.get('MYSQL_HOST','localhost'),
		        'PORT': os.environ.get('MYSQL_PORT','3306'),
		    }
		}

		STATIC_ROOT = os.environ.get('STATIC_ROOT', '/var/www/todobackend/static')
		MEDIA_ROOT = os.environ.get('MEDIA_ROOT', '/var/www/todobackend/media')
This file does the following:
	imports the base settings
	disables debug mode
	specifies allowed hosts 
	add the settings for mysql
	specify the static and media roots for serving static and media content.
The setup.py now needs to include the uwsgi package as a dependency as it is required in the prod env to communicate with nginx. This means we need to recreate the containers as the dependencies have changed - so again we do:
		cd docker/dev
		docker-compose kill
		docker-compose rm -f
		docker-compose build
		docker-compose up agent
		docker-compose up test
		docker-compose up builder

Create the release image:
	mkdir -p ~/cd-docker-ansible//todobackend/docker/release
	cd ~/cd-docker-ansible//todobackend/docker/release
	vi Dockerfile
		FROM garethjones76/todobackend-base:latest
		MAINTAINER Gareth Jones <gareth_jones76@hotmail.com>

		COPY target /wheelhouse

		RUN . /appenv/bin/activate && \
    		pip install --no-index -f /wheelhouse todobackend && \
    		rm -rf /wheelhouse
The Dockerfile is based on the todobackend-base. In addition it copies the built wheel files from /target on the host to /wheelhouse on the docker image. Then it uses the pip install command to install the app - using the "--no-index" flag to stop an internet download, and the "-f" findlinks flag to point to the /wheelhouse folder for the python wheels to be installed. the "todobackend" folder is thename of the application. The "rm" command then cleans up the image by removing the no-longer-required wheelhouse folder.

Next step is to define the Release environment:
The Prod environment will use nginx as a web-server front-end and the uWSGI application to server the dynamic python code (uWSGI is a software application named after the Web Server Gateway Interface which is often used for serving Python web applications in conjunction with web servers such as Nginx, which offers direct support for uWSGI's native uwsgi protocol). The Prod env will also serve static and media content seperately from the dynamic python content.

The Release environment should be as close to Prod as possible so that we have confidence in the UAT testing. So the release env should have an nginx service, a webroot volume container service for static content and a socket for nginx to communicate with uwsgi application service container. It will also need a service container to run the uWSGI and todobackend applications and another service to run the database. For UAT purposes it will also need an agent service to ensure the Db is up.

We create a docker docker-compose.yml falongside the Docker file:
	cat /Users/garethjones/cd-docker-ansible//todobackend/docker/release/docker-compose.yml 
		app:
  		build: ../../
  		dockerfile: docker/release/Dockerfile
		  links:
		    - db
		  environment:
		    DJANGO_SETTINGS_MODULE: todobackend.settings.release
		    MYSQL_HOST: db
		    MYSQL_USER: todo
		    MYSQL_PASSWORD: password
		  volumes_from:
		    - webroot
		  command:
		    - uwsgi
		    - "--socket /var/www/todobackend/todobackend.sock"
		    - "--chmod-socket=666"
		    - "--module todobackend.wsgi"
		    - "--master"
		    - "--die-on-term"

		test:
		  image: garethjones76/todobackend-specs
		  links:
		    - nginx
		  environment:
		    URL: http://nginx:8000/todos
		    JUNIT_REPORT_PATH: /reports/acceptance.xml
		    JUNIT_REPORT_STACK: 1
		  command: --reporter mocha-jenkins-reporter
		
		nginx:
		  build: .
		  dockerfile: Dockerfile.nginx
		  links:
		    - app
		  ports:
		    - "8000:8000"
		  volumes_from:
		    - webroot
		
		webroot:
		  build: ../../
		  dockerfile: docker/release/Dockerfile
		  volumes:
		    - /var/www/todobackend
		  entrypoint: "true"

		db:
		  image: mysql:5.6
		  expose:
		    - "3306"
		  environment:
		    MYSQL_DATABASE: todobackend
		    MYSQL_USER: todo
		    MYSQL_PASSWORD: password
		    MYSQL_ROOT_PASSWORD: password

		agent:
		  image: garethjones76/ansible
		  links:
		    - db
		  environment:
		    PROBE_HOST: "db"
		    PROBE_PORT: "3306"
		  command: ["probe.yml"]

We have to create Dockerfiles for the webroot volume container service and nginx service and we add an nginx configuration file for the nginx service:
	webroot volume service Dockerfile:
		cat ../release/Dockerfile
		FROM garethjones76/todobackend-base:latest
		MAINTAINER Gareth Jones <gareth_jones76@hotmail.com>

		COPY target /wheelhouse

		RUN . /appenv/bin/activate && \
		    pip install --no-index -f /wheelhouse todobackend && \
		    rm -rf /wheelhouse

	nginx service Dockerfile:
		FROM nginx
		MAINTAINER Gareth Jones <gareth_jones76@hotmail.com>
		COPY todobackend.conf /etc/nginx/conf.d/todobackend.conf

	nginx configuration ~/cd-docker-ansible//todobackend/docker/release/todobackend.conf:
		# todobackend_nginx.conf

		# the upstream uWSGI application server
		upstream appserver {
		  server unix:///var/www/todobackend/todobackend.sock;
		}

		# configuration of the server
		server {
		  listen 8000;

		  location /static {
		    alias /var/www/todobackend/static;
		  }

		  location /media {
		    alias /var/www/todobackend/media;
  		}

		  # Send all other requests to the uWSGI application server using uwsgi wire protocol
		  location / {
		    uwsgi_pass  appserver;
		    include     /etc/nginx/uwsgi_params;
		  }
		}

Now we test the Release environment
Common problems with the Release image might be:
	Missing requirements from Base image - usually found on first pass and resolved by fixing the docker-compose file
	Bootstrap issues - usually resolved by specifying initialisation tasks required before the Release tests can run eg db setup

Steps to test:
	docker-compose build		<-- build/rebuild the Release environment
	docker-compose up agent 	<-- check the Db has started before testing
	docker-compose up app	 	<-- bring up the app server service
Note - this step initially fails as uWSGI has a dependency to libpython2.7. We therefore need to add this the the image. We add it to the Base image - as all dependencies required in the release image should be defined in the base image. 
After cleaning, rebuilding and retesting it again fails with a missing dependency to mysqlclient.so.18 so we need to add this to the Base image also. The Dockerfile now loooks like this:
	cat ~/cd-docker-ansible/todobackend-base/Dockerfile
		...
		RUN apt-get update && \
    		apt-get install -qy \
		    -o APT::Install-Recommend=false -o APT::Install-Suggests=false \
		    python python-virtualenv libpython2.7  python-mysqldb
		    ...
After this change we again rebuild the base image:
	cd ~/cd-docker-ansible/todobackend-base/
	docker build -t gjones/todobackend-base .

Then we clean-up the compose environment and retest:
	cd ~/cd-docker-ansible/todobackend/docker/release/
	docker-compose kill
	docker-compose rm -f
	docker-compose build
	docker-compose up agent
	docker-compose up app
	
Now the applcation starts:
	Creating release_webroot_1 ... done
	Creating release_app_1     ... done
	Attaching to release_app_1
	..
	..
	app_1      | spawned uWSGI master process (pid: 1)
	app_1      | spawned uWSGI worker 1 (pid: 14, cores: 1)
	
Note - the app: service is long running and so "captures" the command line. So to get around this and have the app: serive run in background we have added the app: service as a link to the nginx: service in the docker-compose.yml. Because of this link starting nginx will start the app service in the background (Note the nginx: service is also long-running but as it is the front-end and we have exposed the port 8000 to the host so that we can test directly form the host browser, this is not an issue):
	cat /Users/garethjones/cd-docker-ansible//todobackend/docker/release/docker-compose.yml
		...
		...
		nginx:
		  build: .
		  dockerfile: Dockerfile.nginx
		  links:
		    - app
		 ...
		 ...
So now if we bring up the nginx service it also starts the app: service:
	docker-compose up nginx
We can now hit the application from our host browser:
	http://localhost:8000/		<-- brings up our django web page

At this point the application is not formatted correctly - indicating an issue with our static content.
This can also be seen at the terminal in the 404 error messages:
	nginx_1    | 172.17.0.1 - - [19/Oct/2018:11:19:33 +0000] "GET /static/rest_framework/js/csrf.js HTTP/1.1" 404 571 			"http://localhost:8000/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/537.36 (KHTML, like Gecko) 			Chrome/69.0.3497.100 Safari/537.36" "-"

Django apps have a "collect static data" task which is not required in "development mode" so was not required in the test phase. In the Release/Prod phase where debug mode is disabled we need to explicitly run this step.
We could add another service to our docker-compose.yml to achive this:
	...
	collectstatic:
		build: ../../
		dockerfile: docker/release/Dockerfile
		command: manage.py collectstatic

But this adds complication to our docker-compose environment. An alternative is to run the app service, overriding the entrypoint using the "docker-compose run" command:
	
	docker-compose run --rm app manage.py collectstatic --noinput
	
Unlike "docker-compose up", "docker-compose run" allows the services properties to be over-ridden. The rm flag cleans up after the run completes. 
We previously defined STATIC_ROOT in the release.py environment variables so this value (/var/www/todobackend/static) is automatically recognised by collectstatic as the location to output the static content. This is a folder withing the webroot volume service we created so files written here by the collectstatic command are persisted after it completes.
The --noinput flag means there will be no prompting to over-write existing files


Running the command:
	docker-compose run --rm app manage.py collectstatic --noinput
results in many fies being written to the webroot container:
	...
	Copying '/appenv/local/lib/python2.7/site-packages/rest_framework/static/rest_framework/docs/css/highlight.css'
	Copying '/appenv/local/lib/python2.7/site-packages/rest_framework/static/rest_framework/docs/img/grid.png'
	Copying '/appenv/local/lib/python2.7/site-packages/rest_framework/static/rest_framework/docs/img/favicon.ico'

	102 static files copied to '/var/www/todobackend/static'.

Now retrying our browser shows the static content is fixed 

	docker-compose up nginx
	http://localhost:8000/
	
However clicking the "todos": "http://localhost:8000/todos" link throws a "Server Error (500)" indicating a downstream server is not running correctly.

To resolve the 500 error - seton debug mode by setting the DEBUG flag for the app service and restest:
	vi ~/cd-docker-ansible//todobackend/docker/release/docker-compose.yml
	...
	...
	app:
  		build: ../../
  		dockerfile: docker/release/Dockerfile
		  links:
		    - db
		  environment:
		    DJANGO_SETTINGS_MODULE: todobackend.settings.release
		    MYSQL_HOST: db
		    MYSQL_USER: todo
		    MYSQL_PASSWORD: password
		    DEBUG: "true"
	...
	...
(when debugging is complete remember to remove this setting)

Now retest:
	docker-compose kill
	docker-compose up nginx

Now clicking on "todos" gives us the following error:
	Exception Value: (1146, "Table 'todobackend.todo_todoitem' doesn't exist")
	Exception Location:	/appenv/local/lib/python2.7/site-packages/django/db/models/sql/compiler.py in execute_sql, line 899
	
This shows we have missed an initialisation task to populate the mysql db - our mysql migration tasks that we ran in our testing phase have not been run in the release phase.
So again we can use a "docker-compose run" to resolve this:
	docker-compose run --rm app manage.py migrate --noinput

The "todo" option now works as expected
	docker-compose up nginx
	http://localhost:8000/
	
	clicking the "todos": "http://localhost:8000/todos" link now works

The application is now bootstrapping correctly


==============================================================
Section 13 - Acceptance Testing : 
==============================================================
The point of the Release environment is to allow automated UAT testing. In "Section 3 - Acceptance Testing:" we defined our mocha UAT tests in a project call todobacked-specs. We now add a service to reuse these tests and run them against our Release environment.


Once UAT tested our Release image and Application artefacts become release candidates that can be published for deployment into test/staging/prod environments.

The acceptance test service requires a docker image and a docker-compose service. This test service will run UAT tests against the app service in our release environment:
Create a Dockerfile in the todobackend-specs folder
 	vi ~/cd-docker-ansible/todobackend-specs/Dockerfile
		FROM ubuntu:trusty
		MAINTAINER Gareth Jones <gareth_jones76@hotmail.com>

		# Prevent dpkg errors
		ENV TERM=xterm-256color

		# Set mirrors to NZ
		# RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list 

		# Install node.js
		RUN apt-get update && \
		    apt-get install curl -y && \
		    curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash - && \
		    apt-get install -y nodejs 

		COPY . /app
		WORKDIR /app

		# Install application dependencies
		RUN npm install -g mocha && \
		    npm install

		# Set mocha test runner as entrypoint
		ENTRYPOINT ["mocha"]

Dockerfile - based on Ubuntu:trusty image, installs nodejs runtime, COPYs current folder on host to /app on image, sets image WORKDIR to /app, uses npm to install mocha and the required node modules for the acceptance test project.
Finally it sets the ENTRYPOINT to "mocha" - which runs mocha by default.

Add a .dockerignore file to exclude the node_modules folder because it is dynamically generated by the npm install command, and also hidden files such as .gitignore and .dockerignore as they are not required:
	vi ~/cd-docker-ansible/todobackend-specs/.dockerignore
		node_modules
		.*

Add the test service to the docker-compose file:
	vi ~/cd-docker-ansible/todobackend/docker/release/docker-compose.yml
		...
		test:
  		image: garethjones76/todobackend-specs
  		links:
    			- nginx
  		environment:
    			URL: http://nginx:8000/todos
    			JUNIT_REPORT_PATH: /reports/acceptance.xml
    			JUNIT_REPORT_STACK: 1
  		command: --reporter mocha-jenkins-reporter
		...
This service is based on the release environment, links to the nginx service so that the tests can run via the front-end, and includes the URL environment variable. It also specifies some mocha-specific variables specifying the name and location of the test report, and runs  the mocha jenkins reporter by default when the command docker-compose run is issued for this service by defining the "command: --reporter mocha-jenkins-reporter" string

Running the acceptance tests:
First clean and rebuild the environment:
	cd ~/cd-docker-ansible/todobackend/docker/release/
	docker-compose kill
	docker-compose rm -f
	docker-compose build
next start the db, create the db and schema and collect the static content:
	docker-compose up agent
	docker-compose run --rm app manage.py collectstatic --noinput
	docker-compose run --rm app manage.py migrate --noinput

Now run the test servive (which automatically starts the linked nginx service:
	docker-compose up test

All tests should pass. At this stage the app has passed unit, integration and UAT testing and is ready to be tagged and published.

The docker images command shows we have an image named release_app ready to be tagged and deployed:
	docker images|grep -i release
	release_nginx                           latest                   91bc40745862        3 days ago          108MB
	release_app                             latest                   7c870002fc90        3 days ago          452MB
	release_webroot                         latest                   7c870002fc90        3 days ago          452MB

To tag this image we use the docker tag command eg:
	docker tag release_app garethjones76/todobackend:0.1.0
We can publish this to a pubic or private docker repository using :
	docker push
and we can publish the app artefacts (wheels in this case) 

Review:
Test and Build phase: Created a docker-compose.yml that defines our test environment for the test and build stages of the workflow
1) docker-compose build 		<-- builds our images
2) docker-compose up agent		<-- starts our db
3) docker-compose up test		<-- creates cache volume container and runs the tests
4) docker-compose up builder		<-- builds the wheel files to the target folder

Release phase: Created a docker-compose.yml that defines our Release environment 
5) docker-compose build 		<-- builds our images installing wheels form previous test/build stage
6) docker-compose up agent		<-- starts our db
7) docker-compose run --rm app manage.py collectstatic --noinput 	<-- collect static content for nginx
8) docker-compose run --rm app manage.py migrate --noinput		<-- create db schema and tables
9) docker-compose up test		<-- starts nginx & app services, starts test service and runs UAT tests




==============================================================
Section 14 - : 
==============================================================


  

  



 




