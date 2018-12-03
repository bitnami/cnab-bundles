#!/bin/bash
set -eu -o pipefail

########################
#
# RDS helper functions
#
#######################

# Required args
readonly STACK_SUCCESS_STATUSES=(CREATE_COMPLETE UPDATE_COMPLETE)
readonly STACK_FAILED_STATUSES=(CREATE_FAILED ROLLBACK_COMPLETE)

#### Creates a cloud formation stack
rds_provision() {
  STACK_NAME=${STACK_NAME:?}
  DATABASE_PASSWORD=${DATABASE_PASSWORD:?}
  SKIP_DB_CREATION=${SKIP_DB_CREATION:=false}

  if ! ${SKIP_DB_CREATION} ; then
    echo "===> Deploying RDS database"
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
      echo "===> Error creating the database. Status: ${stack_status}"
      exit 1
    elif [[ "${STACK_SUCCESS_STATUSES[@]}" =~ "${stack_status}" ]]; then
      echo STATUS: ${stack_status}
      echo "===> RDS database ready!"
      break
    fi

    tries=$[${tries}+1]
    echo "===> Waiting for the RDS database to be ready, please be patient. Status: ${stack_status}"
    sleep 30
  done

  local DATABASE_HOSTNAME=$(echo "${stack_info}" | jq -r '.Outputs[] | select(.OutputKey == "PublicDnsName").OutputValue')
  echo "===> Database Hostname: ${DATABASE_HOSTNAME}"

  # Store it in a file
  echo ${DATABASE_HOSTNAME} > .rds_hostname
}

# Deprovisions the RDS database by deleting the cloud formation stack
rds_deprovision() {
  aws cloudformation delete-stack --stack-name ${STACK_NAME}
}

########################
#
# Misc helper functions
#
#######################

# Makes a naive validation of the provided credentials by
# 1 - Checking that the client has access to a runner instance of Tiller
# 2 - Validate that the AWS credentials are valid
validate_credentials() {
  echo "===> Validating Kubernetes credentials and Tiller installation"
  helm version > /dev/null || \
    (echo "===> Kubernetes and Tiller validation error" && exit 1)

  echo "===> Validating AWS credentials"
  aws sts get-caller-identity > /dev/null || \
    (echo "===> Invalid AWS credentials" && exit 1)
}

