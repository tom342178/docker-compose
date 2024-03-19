# Makefile

ANYLOG_TYPE := generic
ifneq ($(filter-out $@,$(MAKECMDGOALS)), )
	ANYLOG_TYPE = $(filter-out $@,$(MAKECMDGOALS))
endif

export DOCKER_IMAGE_BASE ?= anylogco/anylog-network
export DOCKER_IMAGE_NAME ?= anylog-network
export DOCKER_IMAGE_VERSION ?= edgelake
#export DOCKER_VOLUME_NAME ?= grafana-storage

# DockerHub ID of the third party providing the image (usually yours if building and pushing)
export DOCKER_HUB_ID ?= anylogco

# The Open Horizon organization ID namespace where you will be publishing the service definition file
export HZN_ORG_ID ?= examples

# Variables required by Home Assistant, can be overridden by your environment variables
#export MY_TIME_ZONE ?= America/New_York

# Open Horizon settings for publishing metadata about the service
export DEPLOYMENT_POLICY_NAME ?= deployment-policy-anylog-$(ANYLOG_TYPE)
export NODE_POLICY_NAME ?= node-policy-anylog-$(ANYLOG_TYPE)
export SERVICE_NAME ?= service-anylog
export SERVICE_VERSION ?= 1.3.2403

# Default ARCH to the architecture of this machine (assumes hzn CLI installed)
export ARCH ?= amd64

# Detect Operating System running Make
OS := $(shell uname -s)

export ANYLOG_VOLUME := anylog-$(ANYLOG_TYPE)-anylog
export BLOCKCHAIN_VOLUME := anylog-$(ANYLOG_TYPE)-blockchain
export DATA_VOLUME := anylog-$(ANYLOG_TYPE)-data
export LOCAL_SCRIPTS := anylog-$(ANYLOG_TYPE)-local-scripts

all: help
login:
	docker login -u anyloguser -p dckr_pat_zcjxcPOKvHkOZMuLY6UOuCs5jUc
build:
	docker pull anylogco/anylog-network:edgelake
up:
	@echo "Deploy AnyLog with config file: anylog_$(ANYLOG_TYPE).env"
	ANYLOG_TYPE=$(ANYLOG_TYPE) envsubst < docker_makefile/docker-compose-template.yaml > docker_makefile/docker-compose.yaml
	@docker-compose -f docker_makefile/docker-compose.yaml up -d
	@rm -rf docker_makefile/docker-compose.yaml
down:
	ANYLOG_TYPE=$(ANYLOG_TYPE) envsubst < docker_makefile/docker-compose-template.yaml > docker_makefile/docker-compose.yaml
	@docker-compose -f docker_makefile/docker-compose.yaml down
	@rm -rf docker_makefile/docker-compose.yaml
clean:
	ANYLOG_TYPE=$(ANYLOG_TYPE) envsubst < docker_makefile/docker-compose-template.yaml > docker_makefile/docker-compose.yaml
	@docker-compose -f docker_makefile/docker-compose.yaml down -v --remove-orphans --rmi all
	@rm -rf docker_makefile/docker-compose.yaml
attach:
	docker attach --detach-keys=ctrl-d anylog-$(ANYLOG_TYPE)
test:
	@if [ "$(ANYLOG_TYPE)" = "master" ]; then \
		curl -X GET 127.0.0.1:32049 -H "command: test node" -H "User-Agent: AnyLog/1.23"; \
	elif [ "$(ANYLOG_TYPE)" = "operator" ]; then \
		curl -X GET 127.0.0.1:32149 -H "command: test node" -H "User-Agent: AnyLog/1.23"; \
	elif [ "$(ANYLOG_TYPE)" = "query" ]; then \
		curl -X GET 127.0.0.1:32349 -H "command: test node" -H "User-Agent: AnyLog/1.23"; \
	elif [ "$(NODE_TYPE)" == "generic" ]; then
	  curl -X GET 127.0.0.1:32549 -H "command: test node" -H "User-Agent: AnyLog/1.23"; \
	fi
exec:
	docker exec -it anylog-$(ANYLOG_TYPE)
logs:
	docker logs anylog-$(ANYLOG_TYPE)

# Makefile for policy
publish-service:
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@hzn exchange service publish -O -P --json-file=policy_deployment/service.definition.json
	@echo ""
remove-service:
	@echo "=================="
	@echo "REMOVING SERVICE"
	@echo "=================="
	@hzn exchange service remove -f $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@echo ""

publish-service-policy:
	@echo "========================="
	@echo "PUBLISHING SERVICE POLICY"
	@echo "========================="
	@hzn exchange service addpolicy -f policy_deployment/service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@echo ""

remove-service-policy:
	@echo "======================="
	@echo "REMOVING SERVICE POLICY"
	@echo "======================="
	@hzn exchange service removepolicy -f $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@echo ""

publish-deployment-policy:
	@echo "============================"
	@echo "PUBLISHING DEPLOYMENT POLICY"
	@echo "============================"
	@export ANYLOG_VOLUME=anylog-$(ANYLOG_TYPE)-anylog
	@export BLOCKCHAIN_VOLUME=anylog-$(ANYLOG_TYPE)-blockchain
	@export DATA_VOLUME=anylog-$(ANYLOG_TYPE)-data
	@export LOCAL_SCRIPTS=anylog-$(ANYLOG_TYPE)-local-scripts
	@hzn exchange deployment addpolicy -f policy_deployment/deployment.policy.$(ANYLOG_TYPE).json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)-$(ANYLOG_TYPE)_$(SERVICE_VERSION)
	@echo ""

remove-deployment-policy:
	@echo "=========================="
	@echo "REMOVING DEPLOYMENT POLICY"
	@echo "=========================="
	@hzn exchange deployment removepolicy -f $(HZN_ORG_ID)/policy-$(SERVICE_NAME)-$(ANYLOG_TYPE)_$(SERVICE_VERSION)
	@echo ""

agent-run:
	@echo "================"
	@echo "REGISTERING NODE"
	@echo "================"
	@hzn register --policy=policy_deployment/node.policy.json
	@watch hzn agreement list

agent-stop:
	@echo "==================="
	@echo "UN-REGISTERING NODE"
	@echo "==================="
	@hzn unregister -f
	@echo ""

deploy-check:
	@hzn deploycheck all -t device -B policy_deployment/deployment.policy.$(ANYLOG_TYPE).json --service=policy_deployment/service.definition.json --service-pol=policy_deployment/service.policy.json --node-pol=policy_deployment/node.policy.json

help:
	@echo "Usage: make [target] [anylog-type]"
	@echo "Targets:"
	@echo "  login       Log into AnyLog docker repository"
	@echo "  build       Pull the docker image"
	@echo "  up          Start the containers"
	@echo "  attach      Attach to AnyLog instance"
	@echo "  test		 Using cURL validate node is running"
	@echo "  exec        Attach to shell interface for container"
	@echo "  down        Stop and remove the containers"
	@echo "  logs        View logs of the containers"
	@echo "  clean       Clean up volumes and network"
	@echo "  help        Show this help message"
	@echo "  supported AnyLog types: generic, master, operator, and query"
	@echo "Sample calls: make up ANYLOG_TYPE=master | make attach ANYLOG_TYPE=master | make clean ANYLOG_TYPE=master"
