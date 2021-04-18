module "vpc2" {
    source = "../../modules/vpc"
    aws_region = "${var.aws_region}"
    cidr = "${var.cidr}"
    cidr-rn = "${var.cidr-rn}"
    sn-cidr-1 = "${var.sn-cidr-1}"
    sn-cidr-2 = "${var.sn-cidr-2}"
    sn-cidr-3 = "${var.sn-cidr-3}"
    vpc_name = "${var.vpc_name}"
    instance_tenancy = "${var.instance_tenancy}"
}