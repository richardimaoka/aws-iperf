#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#   Cloudformation related parameters:
#    --iperf-client-ip  IP address of the EC2 instance running iPerf client 
#    --iperf-server-ip  IP address of the EC2 instance running iPerf server 
#    --instance-type    EC2 instance type for both iPerf client and server

for OPT in "$@"
do
    case "$OPT" in
        '--iperf-client-ip' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "option --wrk-local-ip requires an argument -- $1" 1>&2
                exit 1
            fi
            IPERF_CLIENT_IP="$2"
            shift 2
            ;;
        '--iperf-server-ip' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "option --iperf-client-ip requires an argument -- $1" 1>&2
                exit 1
            fi
            IPERF_SERVER_IP="$2"
            shift 2
            ;;
        '--instance-type' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "option --instance-type requires an argument -- $1" 1>&2
                exit 1
            fi
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -*)
            echo "illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;

    esac
done

# Create the Cloudformation VPC-only stack from the local template `cloudformation-vpc.yaml`
VPC_STACK_NAME="aws-iperf-vpc"
SSH_LOCATION="$(curl ifconfig.co 2> /dev/null)/32"
# aws cloudformation create-stack \
#   --stack-name "${VPC_STACK_NAME}" \
#   --template-body file://cloudformation-vpc.yaml \
#   --capabilities CAPABILITY_NAMED_IAM \
#   --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"

# Create the Cloudformation EC2 stack from `cloudformation-ec2.yaml`
EC2_STACK_NAME="aws-iperf-ec2"
aws cloudformation create-stack \
  --stack-name "${EC2_STACK_NAME}" \
  --template-body file://cloudformation-ec2.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=VPCStackName,ParameterValue="${VPC_STACK_NAME}" \
               ParameterKey=EC2InstanceType,ParameterValue="${INSTANCE_TYPE}" \
               ParameterKey=IPAddressIperfClient,ParameterValue="${IPERF_CLIENT_IP}" \
               ParameterKey=IPAddressIperfServer,ParameterValue="${IPERF_SERVER_IP}"

echo "Waiting until the Cloudformation VPC stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name "${VPC_STACK_NAME}"

echo "Waiting until the Cloudformation EC2 stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name "${EC2_STACK_NAME}"
