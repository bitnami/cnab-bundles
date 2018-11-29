# Source: https://github.com/deislabs/bundles/blob/master/k8sbase/cnab/app/Makefile
SHELL := /bin/bash
CNAB_INSTALLATION_NAME ?= test
CHART_NAME := wordpress
CNAB_P_HELM_OPTIONS ?= # --dry-run

# DATABASE_PASSWORD can be empty, that's why using a simple DATABASE_PASSWORD ?= does not work in our case
# Generate a password if not provided
ifndef DATABASE_PASSWORD
	# Autogenerate database password, alphanumeric 10 chars (RDS does not support symbols)
	DATABASE_PASSWORD := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
endif

ifdef APP_DOMAIN
	HELM_OVERRIDES := --set ingress.enabled=true --set service.type=ClusterIP --set ingress.hosts[0].name=$(APP_DOMAIN)
	ifdef APP_TLS
		HELM_OVERRIDES := $(HELM_OVERRIDES) --set ingress.hosts[0].tls=true --set ingress.hosts[0].certManager=true --set ingress.hosts[0].tlsSecret=$(CNAB_INSTALLATION_NAME).tls
	endif
endif

# TODO, do not rely on the hostname stored in a filename
install: rds_provision
	helm install $(CNAB_P_HELM_OPTIONS) -n $(CNAB_INSTALLATION_NAME) charts/$(CHART_NAME) \
	  --set mariadb.enabled=false,externalDatabase.host=$(shell cat .rds_hostname),externalDatabase.password=$(DATABASE_PASSWORD) \
		$(HELM_OVERRIDES)

uninstall: rds_deprovision
	helm delete $(CNAB_P_HELM_OPTIONS) $(CNAB_INSTALLATION_NAME) --purge

upgrade:
	helm upgrade $(CNAB_P_HELM_OPTIONS) $(CNAB_INSTALLATION_NAME) charts/$(CHART_NAME)

status:
	helm status $(CNAB_P_HELM_OPTIONS) $(CNAB_INSTALLATION_NAME)

rds_provision: .rds_hostname

# provision will create the .rds_hostname file
.rds_hostname:
	@source rds-utils.sh \
		&& STACK_NAME=$(CNAB_INSTALLATION_NAME) SKIP_DB_CREATION=false DATABASE_PASSWORD=$(DATABASE_PASSWORD) provision

rds_deprovision:
	source rds-utils.sh && STACK_NAME=$(CNAB_INSTALLATION_NAME) deprovision

.PHONY: install uninstall upgrade status rds_provision rds_deprovision
