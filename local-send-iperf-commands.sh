#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#   Cloudformation related parameters:
#    --iperf-server-ip  IP address of the EC2 instance running iPerf server 

for OPT in "$@"
do
    case "$OPT" in
        '--iperf-server-ip' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "option --iperf-server-ip requires an argument -- $1" 1>&2
                exit 1
            fi
            IPERF_SERVER_IP="$2"
            shift 2
            ;;
        -*)
            echo "illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;

    esac
done
# Create the Cloudformation VPC-only stack from the local template `cloudformation-vpc.yaml`
EC2_STACK_NAME="aws-iperf-ec2"

# Make sure the web EC2 instance is up and running
IPERF_SERVER_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:aws:cloudformation:stack-name,Values=${EC2_STACK_NAME}" \
            "Name=instance-state-name,Values=running" \
            "Name=tag:Name,Values=iperf-server-instance" \
  --output text --query "Reservations[*].Instances[*].InstanceId")
echo "Waiting until the following web-server EC2 instance is OK: ${IPERF_SERVER_INSTANCE_ID}"
aws ec2 wait instance-status-ok --instance-ids "${IPERF_SERVER_INSTANCE_ID}"

# Run command with Amazon SSM
echo "Running a remote command to start the iperf server on ${IPERF_SERVER_INSTANCE_ID}"
aws ssm send-command \
  --instance-ids "${IPERF_SERVER_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --comment "aws-iperf command to run iperf server" \
  --parameters commands=["iperf3 -s &"] \
  --output text \
  --query "Command.CommandId"

# As of Feb 2019, there is not `wait` command in AWS CLI for Amazon SSM
# So we simply wait here. A better mechanism might be possible though...
sleep 30

# Make sure the web EC2 instance is up and running
IPERF_CLIENT_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:aws:cloudformation:stack-name,Values=${EC2_STACK_NAME}" \
            "Name=instance-state-name,Values=running" \
            "Name=tag:Name,Values=iperf-client-instance" \
  --output text --query "Reservations[*].Instances[*].InstanceId")
echo "Waiting until the following web-server EC2 instance is OK: ${IPERF_CLIENT_INSTANCE_ID}"
aws ec2 wait instance-status-ok --instance-ids "${IPERF_CLIENT_INSTANCE_ID}"

echo "Running a remote command to start the iperf client on ${IPERF_CLIENT_INSTANCE_ID}"
aws ssm send-command \
  --instance-ids "${IPERF_SERVER_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --comment "aws-iperf command to run iperf client" \
  --parameters commands=["iperf3 -c ${IPERF_SERVER_IP}"] \
  --output text \
  --query "Command.CommandId"
