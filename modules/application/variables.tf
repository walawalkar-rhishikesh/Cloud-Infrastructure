variable "aws_region" {
  # description = "Existing VPC to use (specify this, if you don't want to create new VPC)"
  # default     = "us-east-1"
}


variable "vpc_id" {
  description = "Existing VPC to use (specify this, if you don't want to create new VPC)"
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.0.0.0/16"
}

variable "cidr-rn" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "0.0.0.0/0"
}
variable "sn-cidr-1" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.0.101.0/24"
}

variable "sn-cidr-2" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.0.102.0/24"
}

variable "sn-cidr-3" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.0.103.0/24"
}

variable "vpc_name" {
  default     = "csye6225-vpc"
}

variable "instance_tenancy" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "default"
}

variable "s3_bucket_name" {
}

variable "db_instance_identifier" {
  default     = "csye6225-su2020"
}
variable "db_instance_username" {
}
variable "db_instance_password" {
}
variable "db_instance_name" {
}

variable "app_instance_ami_id" {

}

variable "app_sg_frontend_port" {
  default     = 3000
}

variable "app_sg_api_port" {
  default     = 8080
}

variable "app_sg_statsd_port" {
  default     = 8125
}

variable "ami_image_tag_name" {
  default     = "csye6225_ami"
}

variable "AWS_ACCESS_KEY_ID" {
  description = ""
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = ""
}



variable "AWS_ACCOUNT_ID" {
}

# Assignment 6 
variable "s3_codedeploy_bucket_name" {
}
variable "CODE_DEPLOY_APPLICATION_NAME" {
}
variable "circleci_user" {
  default = "circleci"
}

variable "ssl_arn" {
}

variable "db_certs" {
    description = "Using SSL layer for RDS"
    default = "rds-ca-2019"
}

variable "key_usage" {
    description = "Key usage for KMS attribute"
    default = "ENCRYPT_DECRYPT"
}