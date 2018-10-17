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
    python python-virtualenv libpython2.7 python-mysqldb

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

Add three volumes - for wheel files, test reports and builds:
  # OUTPUT: Build artefacts (Wheels) are output here
  VOLUME /wheelhouse
  # OUTPUT: Build cache
  VOLUME /build
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
  # Download requirements to build cache
  pip download -d /build -r requirements_test.txt --no-input
  # Install application test requirements
  pip install --no-index -f /build -r requirements_test.txt
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
Section 9 - Testing using different settings : 
==============================================================

==============================================================
Section 10 - : 
==============================================================


  

  



 




