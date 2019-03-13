# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# import deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
#dpl ?= deploy.env
#include $(dpl)
#export $(shell sed 's/=.*//' $(dpl))

# grep the version from the mix file
VERSION=$(shell ./version.sh)
DOCKER_COMMAND=docker-compose -f docker-compose.yml
DOCKER_COMMAND_SWARM=docker stack deploy
DOCKER_PACKAGE=nginx-php-redis
DOCKER_PACKAGE_FULL=dr4g0nsr/${DOCKER_PACKAGE}

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# DOCKER TASKS
init:
	@echo "TODO"

clean: stop ## Clean all volumes mounted locally to NFS (warning, you WILL lost all data!)
	@docker rm web
	#@rm -rf data/*

# Build the container
buildimage: ## Build the container
	#echo "XX"
	@docker build . -t ${DOCKER_PACKAGE}:latest -t  ${DOCKER_PACKAGE}:1.0

buildimage-nc: ## Build the container without caching
	@docker build . -t ${DOCKER_PACKAGE}:latest -t  ${DOCKER_PACKAGE}:1.0

start: ## Start docker containers using docker-compose
	${DOCKER_COMMAND} up -d

stop: ## Stop and remove a running container
	${DOCKER_COMMAND} stop

remove-dangling: ## Remove all dangling images
	#@docker rmi \$(docker images -q -f dangling=true)
	@docker image prune

kill-containers: stop remove-dangling ## Remove all containers, preserve local data
	@docker system prune -a
	@docker network prune

commit: ## Add changes to git
	@git add * && git commit -m changes && git push

connect: ## Connects to docker container
	@docker exec -it web /bin/bash

multitail: ## Show all logs at once in console
	@docker exec -it web /usr/bin/multitail -s 2 /var/log/nginx/access.log  /var/log/nginx/error.log /var/log/php-fpm.log /tmp/supervisord.log

push: ## Push image to docker hub
	@docker push ${DOCKER_PACKAGE_FULL}

swarm: ## Create docker swarm
	docker stack deploy --compose-file docker-compose-swarm.yml webswarm

refresh: ## Reload images
	@docker pull dr4g0nsr/nginx-php-redis:latest
