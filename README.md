# infrastructure

> Webapp is a web application which is built on NodeJs, Express, MySql and ReactJs. This application is a demostration of various aspect of DevOps and is a part of CSYE6225 Course at Northeastern University. AMI(This) repository is used for creating Amazon Machine Image which will have all the necessary installation required to run the Webapp. On running the shell script, an image is created in AWS. 

## Technology Stack
> - `AWS CLI`    
> - `Terraform`

## Run

> - `TERMINAL`
###### Installation and starting server
```
Unpack terraform and move it to usr/local/bin 
- This makes terraform available throughout
cd --- Project Directory
```

## Authenticate 

```
export AWS_PROFILE="prod"
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_DEFAULT_REGION="us-west-2"
export aws_region="us-east-1"
export s3_bucket_name=""
export db_instance_username=""
export db_instance_password=""
export app_instance_ami_id=""
export db_instance_name=""
export AWS_DEFAULT_REGION="us-west-2"
terraform plan
```

## Steps

```
cd vpc1
terraform init
terraform plan
terraform apply
terraform destroy
```