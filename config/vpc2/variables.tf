variable "aws_region" {
  # description = "Existing VPC to use (specify this, if you don't want to create new VPC)"
  default     = "us-east-1"
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
  default     = "csye6225-vpc-2"
}

variable "instance_tenancy" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "default"
}