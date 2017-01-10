# LumiBash
### Description
This is a script to initiate the deployment of a number ec2 instances.
Subsequently, saltstack is used to configure the instance and deploy an nginx/gunicorn/flask application.

This script can be run from git bash on windows
Configure your aws credentials before running this script. Please use region ap-southeast-2 or the ami won't be found e.g.

```
$aws configure
AWS Access Key ID [********************]:
AWS Secret Access Key [********************]:
Default region name [ap-southeast-2]: 
Default output format [None]:
```
Run the script locally (in bash) with the comand ./ec2 hello dev 1 t1.micro