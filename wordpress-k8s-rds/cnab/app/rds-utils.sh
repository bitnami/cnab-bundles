#!/bin/bash
set -eu -o pipefail

#### Creates a cloud formation stack

# Required args
readonly STACK_SUCCESS_STATUSES=(CREATE_COMPLETE UPDATE_COMPLETE)
readonly STACK_FAILED_STATUSES=(CREATE_FAILED ROLLBACK_COMPLETE)

provision() {
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
    if [[ "${STACK_SUCCESS_STATUSES[@]}" =~ "${stack_status}" ]]; then
      echo STATUS: ${stack_status}
      echo "===> RDS database ready!"
      break
    elif [[ "${STACK_FAILED_STATUSES[@]}" =~ "${stack_status}" ]]; then
      echo "===> Error creating the database. Status: ${stack_status}"
      exit 1
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
# TODO: Wait until the stack is deleted
deprovision() {
  aws cloudformation delete-stack --stack-name ${STACK_NAME}
}
