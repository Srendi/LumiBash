#!/bin/bash
# Filename: ec2.sh
# Author: Gavin Ellis
# Email: srendi@gmail.com
# Description: A wrapper script to instantiate aaws ec2 instances for LumiBlog test. It takes a git repo as user data field to commence saltstack configuration of the instance
# Inputs: <app> (Flask App to run) <environment> (dev,prod...) <num_servers> (Number of ec2 instances to deploy) <server_size> (AWS EC2 instane type, e.g. t1.micro)
# Outputs: n instances configured with OPsGadget blogs
# Notes: 
#
# Usage:
# ec2.sh <app> <environment> <num_servers> <server_size>
# ex: ec2.sh hello_world dev 1 t1.micro

createCount=1
defaultInstanceType="t1.micro"
defaultCount=1
defaultAMIID="ami-020a0f61"
defaultOS="Ubuntu 12.04 LTS"
defaultSecurityGroup="launch-wizard-2"
defaultRegion="ap-southeast-2"
defaultKey="Gavin-Lumi-sandbox-key"
defaultSecurityGroup="launch-wizard-2"
environment="dev"
flaskApp="hello"
instanceID=""

# Run instance
run_instance() {
	instanceID=$(aws ec2 run-instances --image-id $defaultAMIID --count $defaultCount --instance-type $defaultInstanceType --ssh-key-name $defaultKey --user-data-file ./lumiBash.sh --security-groups $defaultSecurityGroup --query 'Instances[0].InstanceId')
	aws ec2 describe-instances --instance-ids $instanceID --query 'Reservations[0].Instances[0].PublicIpAddress'
	}

# Main
#args
case "$#" in
  4)
    defaultInstanceType="$4"
	createCount=$3
	re='^[0-9]+$'
	if ! [[ $createCount =~ $re ]] ; then
		echo "error: Number of servers is Not a number. Defaulting to 1"
		createCount=$defaultCount
	fi
	environment="$2"
	flaskApp=$"1"
    ;;
  *)
    echo "Usage: " $(basename $0) <app> <environment> <num_servers> <server_size>
	echo "Example: "$(basename $0) hello_world dev 1 t1.micro
    exit 1
esac

# Create desired number of instances
for (( c=1; c<=$createCount; c++ ))
do
	run_instance
	sleep 1
done