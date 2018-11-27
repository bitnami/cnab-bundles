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
      --parameters ParameterKey=DatabasePassword,ParameterValue=${DATABASE_PASSWORD} > /dev/null
  fi

  local retries=0
  stack_info=""

  until [ ${retries} -ge 50 ]
  do
    local stack_info="$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --max-items 1 | jq -r .Stacks[0])"
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

    retries=$[${retries}+1]
    echo "===> Waiting for the RDS database to be ready, please be patient. Status: ${stack_status}"
    sleep 30
  done

  local RDS_DNS=$(echo "${stack_info}" | jq '.Outputs[] | select(.OutputKey == "PublicDnsName").OutputValue')
  echo "===> Database Hostname: ${RDS_DNS}"
  echo ${RDS_DNS}
}

# Deprovisions the RDS database by deleting the cloud formation stack
# TODO: Wait until the stack is deleted
deprovision() {
  aws cloudformation delete-stack --stack-name ${STACK_NAME}
}
