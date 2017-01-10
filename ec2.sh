#!/usr/bin/env bash
# Filename: ec2.sh
# Author: Gavin Ellis
# Email: srendi@gmail.com
# Description: A wrapper script to instantiate aws ec2 instances for LumiBlog test. It takes a git repo as user data field to commence saltstack configuration of the instance
# Inputs: <app> (Flask App to run) <environment> (dev,prod...) <num_servers> (Number of ec2 instances to deploy) <server_size> (AWS EC2 instane type, e.g. t1.micro)
# Outputs: n instances configured with OPsGadget blogs
# Notes:  <app> and <env> not yet implemented
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
defaultUserData="user-data-github.sh"
Base64_of_ud_github="IyEvdXNyL2Jpbi9lbnYgYmFzaA0KIyBjZCB+ICYmIHdnZXQgaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1NyZW5kaS9MdW1pQmFzaC9tYXN0ZXIvdXNlci1kYXRhLWdpdGh1Yi5zaCAmJiBjaG1vZCBhK3ggdXNlci1kYXRhLWdpdGh1Yi5zaCAmJiAuL3N1ZG8gdXNlci1kYXRhLWdpdGh1Yi5zaA0KIw0KY2Qgfg0KY3VybCAtTyBodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vU3JlbmRpL0x1bWlCYXNoL21hc3Rlci91c2VyLWRhdGEtbWFzdGVybGVzcy5zaA0KY2htb2QgYSt4IC4vdXNlci1kYXRhLW1hc3Rlcmxlc3Muc2gNCi4vc3VkbyB1c2VyLWRhdGEtbWFzdGVybGVzcy5zaA=="
IPARRAY=()

# Run instance
run_instance() {
	
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
			IPARRAY+=(${publicIP})
			break
		fi
		sleep 1
		echo -n '.'
	done
	# associate elastic ip
	sleep 20
	#eipattached="$(aws ec2 associate-address --instance-id $instanceID --allocation-id eipalloc-acdc8dc9)"  && echo "EIP attached"
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
    echo "Usage: " $(basename $0) "<app> <environment> <num_servers> <server_size>"
	echo "Example: "$(basename $0) hello dev 1 t1.micro
    exit 1
esac

# Create desired number of instances
for (( c=1; c<=$createCount; c++ ))
do
	echo "Creating instance" $c", Please wait"
	run_instance
	sleep 1
done



i=1
for ipaddy in "${IPARRAY[@]}"
do
	echo "Please wait a few moments for instance "$i" to be configured"
	until $(curl --output /dev/null --silent --head --fail http://$ipaddy:80); do
		echo -n '.'
		sleep 1
	done
	echo "\nOpsBlog deployed on instance" $i ": http://"$ipaddy"/"
	i++
done
