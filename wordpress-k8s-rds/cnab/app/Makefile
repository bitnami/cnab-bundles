# Source: https://github.com/deislabs/bundles/blob/master/k8sbase/cnab/app/Makefile
SHELL := /bin/bash
CNAB_ACTION ?= status
CNAB_INSTALLATION_NAME ?= wordpress-test

CNAB_P_HELM_OPTIONS ?= # --dry-run --debug
# Autogenerate database password, alphanumeric 10 chars
DATABASE_PASSWORD ?= $$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)

install: rds_provision
	@for chart in $$(ls charts); do [[ ! -d charts/$$chart ]] || \
		helm install $(CNAB_P_HELM_OPTIONS) -n $(CNAB_INSTALLATION_NAME)-$$chart charts/$$chart ;\
	done
	@echo All charts installed

uninstall: rds_deprovision
	@for chart in $$(ls charts); do [[ ! -d charts/$$chart ]] || \
		helm delete $(CNAB_P_HELM_OPTIONS) $(CNAB_INSTALLATION_NAME)-$$chart ;\
	done

upgrade:
	@for chart in $$(ls charts); do [[ ! -d charts/$$chart ]] || \
		helm upgrade $(CNAB_P_HELM_OPTIONS) $(CNAB_INSTALLATION_NAME)-$$chart charts/$$chart ;\
	done

status:
	@for chart in $$(ls charts); do [[ ! -d charts/$$chart ]] || \
		helm status $(CNAB_P_HELM_OPTIONS) $(CNAB_INSTALLATION_NAME)-$$chart ;\
	done

rds_provision:
	source rds-utils.sh && STACK_NAME=$(CNAB_INSTALLATION_NAME) DATABASE_PASSWORD=$(DATABASE_PASSWORD) provision

rds_deprovision:
	source rds-utils.sh && STACK_NAME=$(CNAB_INSTALLATION_NAME) deprovision

.PHONY: install uninstall upgrade status rds_provision rds_deprovision
