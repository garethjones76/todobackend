PROJECT_NAME ?= todobackend
ORG_NAME ?= gjones
REPO_NAME ?= todobackend


DEV_COMPOSE_FILE := docker/dev/docker-compose.yml
REL_COMPOSE_FILE := docker/release/docker-compose.yml

REL_PROJECT := $(PROJECT_NAME)$(BUILD_ID)
DEV_PROJECT := $(REL_PROJECT)dev 

.PHONY: test build release clean

test:
	${INFO} "Building test images ..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) build
	${INFO} "Start Db ..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up agent
	${INFO} "Running tests ..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up test
	${INFO} "Testing complete ..."


build:
	${INFO} "Build Application ..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up builder
	${INFO} "Copy artefacts to target folder ..."
	@ docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q builder):/wheelhouse/. target
	${INFO} "Build Complete ..."


release:
	${INFO} "Building Release images ..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) build
	${INFO} "Start db Image ..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) up agent
	${INFO} "Distribute static content ..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py collectstatic --noinput
	${INFO} "Migrate Db changes ..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py migrate --noinput
	${INFO} "Running Acceptance Tests ..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) up test
	${INFO} "Acceptance Tests complete ..."

clean:
	${INFO} "Detroying dev env ..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) kill
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) rm -f -v
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) kill
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) rm -f -v
	@ docker images -q -f dangling=true -f label=application$(REPO_NAME) | xargs docker rmi -f ARGS
	${INFO} "Clean Complete ..."


# Cosmetics
YELLOW := "\e[1;33m"
NC := "\e[0m"

# Shell Functions
INFO := @bash -c '\
  printf $(YELLOW); \
  echo "=> $$1"; \
  printf $(NC)' SOME_VALUE