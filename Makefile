ARGS=new-account
BASH=bash
ENVIRONMENT_TAG=staging
SERVICES := auth \
            account \
            notification \
            transactions \
            loan \
            card \
            pkm \
            dmcred \
			gypz-mock \
			gypz-python
DOCKER_REGISTRY=879473356390.dkr.ecr.sa-east-1.amazonaws.com
DEFAULT_REGION=sa-east-1
PULL_COMMANDS := $(foreach service,$(SERVICES),"docker pull -q $(DOCKER_REGISTRY)/$(service):$(ENVIRONMENT_TAG)")
SAFE_LINT=true
UP_RABBIT=true
ROOT=/app
MAXLINELENGTH=120
NEW_ACCOUNT=docker-compose -f docker-compose.yml
NEW_ACCOUNT_DEV=-f docker-compose.dev.yml
DEV=true
DATABASE=account
COLLECTION=account_requests
VERSION=3.7.13-dev


run:
	docker-compose up

stop:
	docker stop $$(docker ps -q) || true

watch:
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) logs -f --tail=100 $(ARGS)

up: update-images recreate-env
	
build:
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) build --build-arg VERSION=$(VERSION)

stop-containers:
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) stop $$ARGS

remove-containers: stop-containers
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) rm -f $$ARGS

lint:
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) exec -T $(ARGS) touch __init__.py
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) exec -T $(ARGS) pylint -j 4 $(ROOT) --rcfile=.pylintrc --output-format=colorized || \
		$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) exec -T $(ARGS) pylint-exit --error-fail --warn-fail --refactor-fail --convention-fail $$? || $(SAFE_LINT)
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) exec -T $(ARGS) rm -f ./__init__.py

coverage:
	$(NEW_ACCOUNT) $(shell $(DEV) && echo $(NEW_ACCOUNT_DEV)) exec -T $(ARGS) pytest --cov-report html:cov_html --cov=./

bash:
	docker-compose exec $(ARGS) $(BASH)

fix:
	docker-compose exec $(ARGS) autopep8 --in-place -a --max-line-length $(MAXLINELENGTH) -r $(ROOT)

test: docker-compose exec backend bash /app/starters/tests-start.sh -x
