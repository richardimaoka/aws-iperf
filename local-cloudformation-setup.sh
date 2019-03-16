#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Create the Cloudformation VPC-only stack from the local template `cloudformation-vpc-main.yaml`
AWS_ACCOUNT_ID="$(aws sts get-caller-identity | jq -r '.Account')" \
SSH_LOCATION="$(curl ifconfig.co 2> /dev/null)/32"
MAIN_VPC_STACK_NAME="MainVPCStack"
aws cloudformation create-stack \
  --stack-name "${MAIN_VPC_STACK_NAME}" \
  --template-body file://cloudformation-vpc-main.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}" \
               ParameterKey=PeerRequesterAccountId,ParameterValue="${AWS_ACCOUNT_ID}"

# Create the Cloudformation VPC-only stack from the local template `cloudformation-vpc-sub.yaml`
SUB_VPC_STACK_NAME="SubVPCStack"
aws cloudformation create-stack \
  --stack-name "${SUB_VPC_STACK_NAME}" \
  --template-body file://cloudformation-vpc-sub.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}" \
               ParameterKey=PeerVPCAccountId,ParameterValue="${AWS_ACCOUNT_ID}"

echo "Waiting until the Cloudformation VPC main stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name "${MAIN_VPC_STACK_NAME}"

echo "Waiting until the Cloudformation VPC sub stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name "${SUB_VPC_STACK_NAME}"

for params in $(jq -c '.[]' local-parameters.json)
do
  EC2_STACK_NAME="abcedga"
  aws cloudformation create-stack \
    --stack-name "${EC2_STACK_NAME}" \
    --template-body file://cloudformation-ec2.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters ParameterKey=EC2InstanceType,ParameterValue="$(echo ${params} | jq -r '.instance_type')" \
                 ParameterKey=IPerfServerStack,ParameterValue="$(echo ${params} | jq -r '.iperf_server_stack')" \
                 ParameterKey=IPerfClientStack,ParameterValue="$(echo ${params} | jq -r '.iperf_client_stack')" \
                 ParameterKey=IPerfServerSubnet,ParameterValue="$(echo ${params} | jq -r '.iperf_server_subnet')" \
                 ParameterKey=IPerfClientSubnet,ParameterValue="$(echo ${params} | jq -r '.iperf_client_subnet')" \
                 ParameterKey=IPerfServerIPAddress,ParameterValue="$(echo ${params} | jq -r '.iperf_server_ip_address')" \
                 ParameterKey=IPerfClientIPAddress,ParameterValue="$(echo ${params} | jq -r '.iperf_client_ip_address')"
done
