provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "main_vpc" {
  cidr_block       = "${var.cidr}"
  instance_tenancy = "${var.instance_tenancy}"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "aws_subnet" "subnet_1" {
  vpc_id     = "${aws_vpc.main_vpc.id}"
  cidr_block = "${var.sn-cidr-1}"
  availability_zone =   "${data.aws_availability_zones.available_zones.names[0]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = "${aws_vpc.main_vpc.id}"
  cidr_block = "${var.sn-cidr-2}"
  availability_zone =   "${data.aws_availability_zones.available_zones.names[1]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-subnet-2"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id     = "${aws_vpc.main_vpc.id}"
  cidr_block = "${var.sn-cidr-3}"
  availability_zone =   "${data.aws_availability_zones.available_zones.names[2]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-subnet-3"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
    vpc_id = "${aws_vpc.main_vpc.id}"
    tags = {
        Name = "${var.vpc_name}-internetgateway"
    }
}

resource "aws_route_table" "main-rn" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  route {
    cidr_block = "${var.cidr-rn}"
    gateway_id = "${aws_internet_gateway.internet-gateway.id}"
  }

  tags = {
    Name = "${var.vpc_name}-main-rn"
  }
}
resource "aws_route_table_association" "rtasc-1" {
  subnet_id      = "${aws_subnet.subnet_1.id}"
  route_table_id = "${aws_route_table.main-rn.id}"
}

resource "aws_route_table_association" "rtasc-2" {
  subnet_id      = "${aws_subnet.subnet_2.id}"
  route_table_id = "${aws_route_table.main-rn.id}"
}

resource "aws_route_table_association" "rtasc-3" {
  subnet_id      = "${aws_subnet.subnet_3.id}"
  route_table_id = "${aws_route_table.main-rn.id}"
}
resource "aws_route" "default-route" {
    route_table_id = "${aws_route_table.main-rn.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet-gateway.id}"
}
