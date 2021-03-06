#!/bin/bash
set -eu -o pipefail

########################
#
# Misc helper functions
#
########################

# Makes a naive validation of the provided credentials by
# 1 - Checking that the client has access to a runner instance of Tiller
# 2 - Helm client and server are compatible
# 3 - Validate that the AWS credentials are valid
validate_credentials() {
  local chart_path=${1:?}
  log "Validating Kubernetes credentials and Tiller installation"
  # We do a dry run to detect imcompatibilities between the client and the server
  helm install --dry-run ${chart_path} > /dev/null || \
    (log "Kubernetes and Tiller validation error" && exit 1)

  log "Validating AWS credentials"
  aws sts get-caller-identity > /dev/null || \
    (log "Invalid AWS credentials" && exit 1)
}

log() {
  echo -e "\033[0;33m$(date "+%H:%M:%S")\033[0;37m ==> $1."
}

########################
#
# RDS helper functions
#
########################

# Required args
readonly STACK_SUCCESS_STATUSES=(CREATE_COMPLETE UPDATE_COMPLETE)
readonly STACK_FAILED_STATUSES=(CREATE_FAILED ROLLBACK_COMPLETE)

#### Creates a cloud formation stack
rds_provision() {
  STACK_NAME=${STACK_NAME:?}
  DATABASE_PASSWORD=${DATABASE_PASSWORD:?}
  SKIP_DB_CREATION=${SKIP_DB_CREATION:=false}

  if ! ${SKIP_DB_CREATION} ; then
    log "Deploying RDS database"
    aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://rds-cft.json \
      --parameters ParameterKey=DatabasePassword,ParameterValue=${DATABASE_PASSWORD} \
      ParameterKey=DatabaseUsername,ParameterValue=bn_wordpress \
      ParameterKey=DatabaseName,ParameterValue=bitnami_wordpress > /dev/null
  fi

  local tries=0
  stack_info=""

  until [ ${tries} -ge 50 ]
  do
    local stack_info="$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --max-items 1 | jq .Stacks[0])"
    local stack_status="$(echo ${stack_info} | jq -r .StackStatus)"

    # TODO, use regexp
    if [[ "${STACK_FAILED_STATUSES[@]}" =~ "${stack_status}" ]]; then
      log "Error creating the database. Status: ${stack_status}"
      exit 1
    elif [[ "${STACK_SUCCESS_STATUSES[@]}" =~ "${stack_status}" ]]; then
      log "RDS database ready!"
      break
    fi

    tries=$[${tries}+1]
    log "Waiting for the RDS database to be ready, please be patient. Status: ${stack_status}"
    sleep 30
  done

  local DATABASE_HOSTNAME=$(echo "${stack_info}" | jq -r '.Outputs[] | select(.OutputKey == "PublicDnsName").OutputValue')
  log "Database Hostname: ${DATABASE_HOSTNAME}"

  # Store it in a file
  echo ${DATABASE_HOSTNAME} > .rds_hostname
}

# Deprovisions the RDS database by deleting the cloud formation stack
rds_deprovision() {
  aws cloudformation delete-stack --stack-name ${STACK_NAME}
}
