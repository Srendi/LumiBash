#!/usr/bin/env bash
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
defaultSecurityGroup="Gavin-Application-Task"
defaultRegion="ap-southeast-2"
defaultKey="Gavin-Lumi-sandbox-key"
environment="dev"
flaskApp="hello"
defaultPlacement="AvailabilityZone=ap-southeast-2b"
defaultUserData="lummiBash.sh"

# Run instance
run_instance() {
	echo "Creating instance, Please wait"
	currentDir=$(pwd)
	userData="file://./$defaultUserData"
	#echo $userData
	instanceIDtmp="$(aws ec2 run-instances --image-id $defaultAMIID --count $defaultCount --instance-type $defaultInstanceType --placement $defaultPlacement --key-name $defaultKey --user-data $userData --security-groups $defaultSecurityGroup --query 'Instances[0].InstanceId')"
	instanceID="${instanceIDtmp//\"}"
	echo "Instance id ${instanceID}"
	aws ec2 wait --region ap-southeast-2 instance-running --instance-ids $instanceID
	while true; do
		publicIPtmp="$(aws ec2 describe-instances --instance-ids ${instanceID} --query 'Reservations[0].Instances[0].PublicIpAddress')"

		publicIP="${publicIPtmp//\"}"
		if [[ "${publicIP}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
			echo "Public IP Address: ${publicIP}"
			break
		fi
		sleep 1
		echo -n '.'
	done
	# associate elastic ip
	sleep 20
	aws ec2 associate-address --instance-id $instanceID --allocation-id eipalloc-acdc8dc9
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
	if [[ $flaskApp != "hello" ]]
	then
		echo "Currently only hello app is supported"
		# To change app name from an appname available in the github repo:
		# sed 's/usedApp=.*/usedApp=$1/g' lumiBash.sh
		# sed 's/usedAppChanged=.*/usedAppChanged=1/g' lumiBash.
		flaskApp="hello"
	fi
    ;;
  *)
    echo "Usage: " $(basename $0) "<app> <environment> <num_servers> <server_size>"
	echo "Example: "$(basename $0) hello dev 1 t1.micro
    exit 1
esac

# Create desired number of instances
for (( c=1; c<=$createCount; c++ ))
do
	run_instance
	sleep 1
done