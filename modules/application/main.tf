provider "aws" {
  region = "${var.aws_region}"
}

# Creating VPC
resource "aws_vpc" "app_vpc" {
  cidr_block       = "${var.cidr}"
  instance_tenancy = "${var.instance_tenancy}"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

data "aws_availability_zones" "app_available_zones" {
  state = "available"
}

# Creating three SUBNETS
resource "aws_subnet" "app_subnet_one" {
  vpc_id     = "${aws_vpc.app_vpc.id}"
  cidr_block = "${var.sn-cidr-1}"
  availability_zone =   "${data.aws_availability_zones.app_available_zones.names[0]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}_app_subnet_one"
  }
}

resource "aws_subnet" "app_subnet_two" {
  vpc_id     = "${aws_vpc.app_vpc.id}"
  cidr_block = "${var.sn-cidr-2}"
  availability_zone =   "${data.aws_availability_zones.app_available_zones.names[1]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}_app_subnet_two"
  }
}

resource "aws_subnet" "app_subnet_three" {
  vpc_id     = "${aws_vpc.app_vpc.id}"
  cidr_block = "${var.sn-cidr-3}"
  availability_zone =   "${data.aws_availability_zones.app_available_zones.names[2]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}_app_subnet_three"
  }
}

#Creating Internet Gateway
resource "aws_internet_gateway" "app_internet_gateway" {
  vpc_id = "${aws_vpc.app_vpc.id}"
  tags = {
      Name = "${var.vpc_name}_app_internet_gateway"
  }
}

#Creating Route Table
resource "aws_route_table" "app_main_routing_table" {
  vpc_id = "${aws_vpc.app_vpc.id}"
  route {
    cidr_block = "${var.cidr-rn}"
    gateway_id = "${aws_internet_gateway.app_internet_gateway.id}"
  }
  tags = {
    Name = "${var.vpc_name}_app_main_routing_table"
  }
}

#Associating RouteTables
resource "aws_route_table_association" "app_route_table_association_subnet_one" {
  subnet_id      = "${aws_subnet.app_subnet_one.id}"
  route_table_id = "${aws_route_table.app_main_routing_table.id}"
}

resource "aws_route_table_association" "app_route_table_association_subnet_two" {
  subnet_id      = "${aws_subnet.app_subnet_two.id}"
  route_table_id = "${aws_route_table.app_main_routing_table.id}"
}

resource "aws_route_table_association" "app_route_table_association_subnet_three" {
  subnet_id      = "${aws_subnet.app_subnet_three.id}"
  route_table_id = "${aws_route_table.app_main_routing_table.id}"
}

#Creating Default Route
resource "aws_route" "default_route" {
  route_table_id = "${aws_route_table.app_main_routing_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.app_internet_gateway.id}"
}

resource "aws_security_group" "app_loadbalancer_security_group" {
    name = "app_loadbalancer_security_group"
    description = "Enable HTTPS via port 3000"

    vpc_id = "${aws_vpc.app_vpc.id}"

    # ingress {
    #     to_port = 22
    #     from_port = 22
    #     protocol = "tcp"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }
    
    ingress {
        to_port = 80
        from_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        to_port = 443
        from_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = "${var.app_sg_statsd_port}"
        to_port     = "${var.app_sg_statsd_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }    

    ingress {
        from_port   = "${var.app_sg_frontend_port}"
        to_port     = "${var.app_sg_frontend_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # ingress {
    #     to_port = 4000
    #     from_port = 4000
    #     protocol = "tcp"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }

    ingress {
        from_port   = "${var.app_sg_api_port}"
        to_port     = "${var.app_sg_api_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.vpc_name}_app_loadbalancer_security_group"
    }
}

## Security Group##
resource "aws_security_group" "app_application_security_group" {
  description = "Allow limited inbound external traffic"
  vpc_id     = "${aws_vpc.app_vpc.id}"
  name        = "application"

  # ingress {
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  #   from_port   = 22
  #   to_port     = 22
  # }

  ingress {
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    security_groups = ["${aws_security_group.app_loadbalancer_security_group.id}"]
  }

  ingress {
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    security_groups = ["${aws_security_group.app_loadbalancer_security_group.id}"]
  }

  ingress {
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    from_port   = "${var.app_sg_frontend_port}"
    to_port     = "${var.app_sg_frontend_port}"
    security_groups = ["${aws_security_group.app_loadbalancer_security_group.id}"]
  }

  ingress {
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    from_port   = "${var.app_sg_api_port}"
    to_port     = "${var.app_sg_api_port}"
    security_groups = ["${aws_security_group.app_loadbalancer_security_group.id}"]
  }

  ingress {
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    from_port   = "${var.app_sg_statsd_port}"
    to_port     = "${var.app_sg_statsd_port}"
    security_groups = ["${aws_security_group.app_loadbalancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}_app_application_security_group"
  }
}

resource "aws_security_group" "app_database_security_group" {
  description = "Allow limited inbound external traffic"
  vpc_id     = "${aws_vpc.app_vpc.id}"
  name        = "database"

  ingress {
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3306
    to_port     = 3306
    security_groups = ["${aws_security_group.app_application_security_group.id}"]
  }

  tags = {
    Name = "${var.vpc_name}_app_database_security_group"
  }
}

resource "aws_s3_bucket" "application_s3_bucket" {
  bucket = "${var.s3_bucket_name}"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "app_s3_lifecycle_rule"
    enabled = true

    tags = {
      "rule"      = "app_s3_lifecycle_rule"
      "autoclean" = "true"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }

  tags = {
    Name        = "${var.vpc_name}_application_s3_bucket"
    Environment = "Dev"
  }
}

resource "aws_iam_role" "application_ec2_s3_role" {
  name = "EC2-CSYE6225"

  assume_role_policy = "${file("ec2s3role.json")}"

  tags = {
    Name = "EC2-Iam role"
  }
}

#Creating IAM policy
resource "aws_iam_policy" "application_ec2_s3_policy" {
  name        = "WebAppEC2S3Policy"
  description = "S3 bucket policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:DeleteObject",
            "s3:DeleteObjectVersion"
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::${var.s3_bucket_name}",
              "arn:aws:s3:::${var.s3_bucket_name}/*"
          ]
      }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_s3_role_policy_attachment" {
  role       = "${aws_iam_role.application_ec2_s3_role.name}"
  policy_arn = "${aws_iam_policy.application_ec2_s3_policy.arn}"
}

#Profile for attachment to EC2 instance
resource "aws_iam_instance_profile" "APPEC2InstanceProfile" {
  name = "APPEC2InstanceProfile"
  role = "${aws_iam_role.application_ec2_s3_role.name}"
}

resource "aws_db_subnet_group" "app_db_subnet_group" {
  name       = "${var.vpc_name}_app_db_subnet_group"
  subnet_ids = ["${aws_subnet.app_subnet_one.id}", "${aws_subnet.app_subnet_two.id}","${aws_subnet.app_subnet_three.id}"]

  tags = {
    Name  = "${var.vpc_name}_app_db_subnet_group"
  }
}


resource "aws_db_instance" "application_rds_instance" {
  identifier           = "${var.db_instance_identifier}"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "${var.db_instance_username}"
  password             = "${var.db_instance_password}"
  multi_az             = false
  publicly_accessible  = false
  name                 = "${var.db_instance_name}"
  db_subnet_group_name = "${aws_db_subnet_group.app_db_subnet_group.name}"
  skip_final_snapshot = true

  vpc_security_group_ids = [
    "${aws_security_group.app_database_security_group.id}"
  ]
  allocated_storage     = 20
  kms_key_id           = "${aws_kms_key.rds_encryption.arn}"
  storage_encrypted = true
}

resource "aws_kms_key" "rds_encryption" {
  description             = "KMS key for RDS"
  key_usage               = "${var.key_usage}"
  policy                  = "${file("kms_policy.json")}"
  is_enabled              = true
  tags = {
    "Name" = "KMS for RDS"
  }
}
# SHIFTED TO THE BOTTOM


# resource "aws_instance" "application_instance" {
#   ami           = "${var.app_instance_ami_id}"
#   instance_type = "t2.micro"

#   vpc_security_group_ids = [
#     "${aws_security_group.app_application_security_group.id}"
#   ]
#   key_name                = "csye_6225_ec2_ami"
#   subnet_id = "${aws_subnet.app_subnet_one.id}"
#   root_block_device {
#     delete_on_termination = false
#     volume_type = "gp2"
#     volume_size = 20
#   }

#   tags = {
#     Name = "${var.vpc_name}_application_rds_instance"
#   }
#   depends_on = [
#     aws_db_instance.application_rds_instance
#   ] 
  
#   iam_instance_profile    = "${aws_iam_instance_profile.APPEC2InstanceProfile.name}"
#   user_data = <<-EOF
#         #!/bin/bash
#         echo "export aws_region=${var.aws_region}">> /home/ubuntu/.bashrc
#         echo "export s3_bucket_name=${var.s3_bucket_name}">> /home/ubuntu/.bashrc
#         echo "export db_instance_username=${var.db_instance_username}">> /home/ubuntu/.bashrc
#         echo "export db_instance_password=${var.db_instance_password}">> /home/ubuntu/.bashrc
#         echo "export app_instance_ami_id=${var.app_instance_ami_id}">> /home/ubuntu/.bashrc
#         echo "export app_db_name=${var.db_instance_name}">> /home/ubuntu/.bashrc
#         echo "export app_db_hostname=${aws_db_instance.application_rds_instance.address}">> /home/ubuntu/.bashrc
#         echo "export AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}">> /home/ubuntu/.bashrc
#         echo "export AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_ACCESS_KEY}">> /home/ubuntu/.bashrc
#     EOF
# }

#Creating DynamoDb 
resource "aws_dynamodb_table" "csye-dynamodb-table" {
  name           = "csye6225"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UId"

  attribute {
    name = "UId"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  tags = {
    Name        = "csye-dynamodb-table"
    Environment = "production"
  }
}

# Assignment 6 

resource "aws_s3_bucket" "application_codedeploy_s3_bucket" {
  bucket = "${var.s3_codedeploy_bucket_name}"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "app_codedeploy_s3_lifecycle_rule"
    enabled = true

    tags = {
      "rule"      = "app_codedeploy_s3_lifecycle_rule"
      "autoclean" = "true"
    }

    expiration {
      days = 30
      expired_object_delete_marker = true
    }
  }

  tags = {
    Name        = "${var.vpc_name}_application_codedeploy_s3_bucket"
    Environment = "Prod"
  }
}

resource "aws_iam_policy" "app_codedeploy_ec2_s3_access_policy" {
  name = "CodeDeploy-EC2-S3"
  description = "Policy which allows ec2 role to access S3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectVersion",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.s3_codedeploy_bucket_name}/*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_policy" "app_circleci_ec2_s3_upload_policy" {
  name = "CircleCI-Upload-To-S3"
  description = "Policy which allows ec2 role to upload on S3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.s3_codedeploy_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "app_circleci_code_deploy_policy" {
  name = "CircleCI-Code-Deploy"
  description = "Allows CircleCI to upload artifacts from latest successful build to dedicated S3 bucket used by CodeDeploy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.aws_region}:${var.AWS_ACCOUNT_ID}:application:${var.CODE_DEPLOY_APPLICATION_NAME}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.aws_region}:${var.AWS_ACCOUNT_ID}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.aws_region}:${var.AWS_ACCOUNT_ID}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.aws_region}:${var.AWS_ACCOUNT_ID}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "app_circleci_ec2_ami_policy" {
  name = "CircleCI-ec2-ami"
  description = "Allows the minimal set permissions necessary for circleci user in Packer to work"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CopyImage",
                "ec2:CreateImage",
                "ec2:CreateKeypair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteKeyPair",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSnapshot",
                "ec2:DeleteVolume",
                "ec2:DeregisterImage",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeRegions",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetPasswordData",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifySnapshotAttribute",
                "ec2:RegisterImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "app_circleci_ec2_s3_upload_policy_attachment" {
  user       = "${var.circleci_user}"
  policy_arn = "${aws_iam_policy.app_circleci_ec2_s3_upload_policy.arn}"
}

resource "aws_iam_user_policy_attachment" "app_circleci_code_deploy_policy_attachment" {
  user       = "${var.circleci_user}"
  policy_arn = "${aws_iam_policy.app_circleci_code_deploy_policy.arn}"
}

resource "aws_iam_user_policy_attachment" "app_circleci_ec2_ami_policy_attachment" {
  user       = "${var.circleci_user}"
  policy_arn = "${aws_iam_policy.app_circleci_ec2_ami_policy.arn}"
}

resource "aws_iam_role" "app_codedeploy_ec2_host_service_role" {
  name = "CodeDeployEC2ServiceRole"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": "ec2.amazonaws.com"
},
"Effect": "Allow",
"Sid": ""
}
]
}
EOF

  tags = {
    Name = "CodeDeployEC2ServiceRole"
  }

}

resource "aws_iam_role_policy_attachment" "app_codedeploy_host_service_access_attachment" {
  role       = "${aws_iam_role.app_codedeploy_ec2_host_service_role.name}"
  policy_arn = "${aws_iam_policy.app_codedeploy_ec2_s3_access_policy.arn}"
}

resource "aws_iam_role" "app_codedeploy_service_role" {
  name = "CodeDeployServiceRole"
  description = "Role for code deploy"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    Name = "CodeDeployServiceRole"
  }
}

resource "aws_iam_role_policy_attachment" "app_codedeploy_service_role_awscodedeployrole_attachment" {
  role       = "${aws_iam_role.app_codedeploy_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "app_codedeply_service_role_rdsaccess_attachment" {
  role       = "${aws_iam_role.app_codedeploy_ec2_host_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "app_codedeply_service_role_cloudwatch_attachment" {
  role       = "${aws_iam_role.app_codedeploy_ec2_host_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "app_codedeply_service_role_cloudwatch_admin_attachment" {
  role       = "${aws_iam_role.app_codedeploy_ec2_host_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_instance_profile" "app_codedeploy_service_role_profile" {
  name = "CodeDeployEC2InstanceProfile"
  role = "${aws_iam_role.app_codedeploy_ec2_host_service_role.name}"
}

# resource "aws_instance" "application_instance" {
#   ami           = "${var.app_instance_ami_id}"
#   instance_type = "t2.micro"

#   vpc_security_group_ids = [
#     "${aws_security_group.app_application_security_group.id}"
#   ]
#   key_name                = "csye_6225_ec2_ami"
#   subnet_id = "${aws_subnet.app_subnet_one.id}"
#   root_block_device {
#     delete_on_termination = false
#     volume_type = "gp2"
#     volume_size = 20
#   }

#   tags = {
#     Name = "${var.vpc_name}_application_instance"
#   }
#   depends_on = [
#     aws_db_instance.application_rds_instance
#   ] 
  
#   iam_instance_profile    = "${aws_iam_instance_profile.app_codedeploy_service_role_profile.name}"
#   user_data = <<-EOF
#         #!/bin/bash
#         echo export "aws_region=${var.aws_region}" | sudo tee -a /etc/environment
#         echo export "s3_bucket_name=${var.s3_bucket_name}" | sudo tee -a /etc/environment
#         echo export "aws_region=${var.aws_region}" | sudo tee -a /etc/environment
#         echo export "s3_bucket_name=${var.s3_bucket_name}" | sudo tee -a /etc/environment
#         echo export "db_instance_username=${var.db_instance_username}" | sudo tee -a /etc/environment
#         echo export "db_instance_password=${var.db_instance_password}" | sudo tee -a /etc/environment
#         echo export "app_instance_ami_id=${var.app_instance_ami_id}" | sudo tee -a /etc/environment
#         echo export "app_db_name=${var.db_instance_name}" | sudo tee -a /etc/environment
#         echo export "app_db_hostname=${aws_db_instance.application_rds_instance.address}" | sudo tee -a /etc/environment
#         echo export "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}" | sudo tee -a /etc/environment
#         echo export "AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_ACCESS_KEY}" | sudo tee -a /etc/environment
#     EOF
# }

resource "aws_launch_configuration" "app_launch_configuration" {
  name = "applaunchconfiguration"
  image_id = "${var.app_instance_ami_id}"
  instance_type = "t2.micro"
  key_name = "csye_6225_ec2_ami"
  associate_public_ip_address = true
  root_block_device {
    delete_on_termination = false
    volume_type = "gp2"
    volume_size = 20
  }
  user_data = <<-EOF
    #!/bin/bash
    echo export "aws_region=${var.aws_region}" | sudo tee -a /etc/environment
    echo export "s3_bucket_name=${var.s3_bucket_name}" | sudo tee -a /etc/environment
    echo export "aws_region=${var.aws_region}" | sudo tee -a /etc/environment
    echo export "s3_bucket_name=${var.s3_bucket_name}" | sudo tee -a /etc/environment
    echo export "db_instance_username=${var.db_instance_username}" | sudo tee -a /etc/environment
    echo export "db_instance_password=${var.db_instance_password}" | sudo tee -a /etc/environment
    echo export "app_instance_ami_id=${var.app_instance_ami_id}" | sudo tee -a /etc/environment
    echo export "app_db_name=${var.db_instance_name}" | sudo tee -a /etc/environment
    echo export "app_db_hostname=${aws_db_instance.application_rds_instance.address}" | sudo tee -a /etc/environment
    echo export "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}" | sudo tee -a /etc/environment
    echo export "AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_ACCESS_KEY}" | sudo tee -a /etc/environment
  EOF
  iam_instance_profile    = "${aws_iam_instance_profile.app_codedeploy_service_role_profile.name}"
  security_groups= ["${aws_security_group.app_application_security_group.id}"]
  depends_on = [
    aws_db_instance.application_rds_instance
  ]
}

resource "aws_autoscaling_group" "app_autoscaling_group" {
  name                      = "appautoscalinggroup"
  max_size                  = 5
  min_size                  = 2
  default_cooldown          = 60
  desired_capacity          = 2
  launch_configuration      = "${aws_launch_configuration.app_launch_configuration.name}"
  vpc_zone_identifier       = ["${aws_subnet.app_subnet_one.id}", "${aws_subnet.app_subnet_two.id}", "${aws_subnet.app_subnet_three.id}"]
  target_group_arns         = ["${aws_lb_target_group.app_lb_tg_frontend.arn}","${aws_lb_target_group.app_lb_tg_backend.arn}"]
  # target_group_arns         = ["${aws_lb_target_group.lb_tg_webapp.arn}"]
  tags = [
    {
      key                 = "Name"
      value               = "${var.vpc_name}_application_instance"
      propagate_at_launch = true
    }
  ]
}

resource "aws_autoscaling_policy" "app_autoscaling_scaleup_policy" {
  name                   = "appautoscalingscaleuppolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.app_autoscaling_group.name}"
}

resource "aws_autoscaling_policy" "app_autoscaling_scaledown_policy" {
  name                   = "appautoscalingscaledownpolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.app_autoscaling_group.name}"
}

resource "aws_cloudwatch_metric_alarm" "app_cloudwatch_metric_high_alarm" {
  alarm_name                = "app_cloudwatch_metric_high_alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "5"
  dimensions                = "${map("AutoScalingGroupName", "${aws_autoscaling_group.app_autoscaling_group.name}")}"
  alarm_description         = "Scale-up if CPU > 5% for 2 minutes"
  alarm_actions             = ["${aws_autoscaling_policy.app_autoscaling_scaleup_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "app_cloudwatch_metric_low_alarm" {
  alarm_name                = "app_cloudwatch_metric_high_alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "3"
  alarm_description         = "Scale-down if CPU < 3% for 2 minutes"
  dimensions                = "${map("AutoScalingGroupName", "${aws_autoscaling_group.app_autoscaling_group.name}")}"
  alarm_actions             = ["${aws_autoscaling_policy.app_autoscaling_scaledown_policy.arn}"]
}

resource "aws_lb" "app_load_balancer" {
  name = "apploadbalancer"
  subnets = ["${aws_subnet.app_subnet_one.id}", "${aws_subnet.app_subnet_two.id}", "${aws_subnet.app_subnet_three.id}"]
  security_groups = ["${aws_security_group.app_loadbalancer_security_group.id}"]
  ip_address_type = "ipv4"
  # enable_deletion_protection = true
  tags = {
    Name = "app_load_balancer"
  }
}

resource "aws_lb_target_group" "app_lb_tg_frontend" {
  name     = "applbtgfrontend"
  target_type = "instance"
  health_check {
    interval = 125
    timeout = 120
    healthy_threshold = 3
    unhealthy_threshold = 3
    path = "/"
    port = 3000
  }
  deregistration_delay = 20
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.app_vpc.id}"
}

resource "aws_lb_target_group" "app_lb_tg_backend" {
  name     = "applbtgbackend"
  target_type = "instance"
  health_check {
    interval = 125
    timeout = 120
    healthy_threshold = 3
    unhealthy_threshold = 3
    path = "/"
    port = 8080
  }
  deregistration_delay = 20
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.app_vpc.id}"
}

resource "aws_lb_listener" "app_lb_listener_frontend" {
  load_balancer_arn = "${aws_lb.app_load_balancer.arn}"
  port              = "3000"
  protocol          = "HTTPS"
  # certificate_arn   = "${data.aws_acm_certificate.certificate.arn}"
  certificate_arn   = "${var.ssl_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.app_lb_tg_frontend.arn}"
  }
}

resource "aws_lb_listener" "app_lb_listener_backend" {
  load_balancer_arn = "${aws_lb.app_load_balancer.arn}"
  port              = "8080"
  protocol          = "HTTPS"
  certificate_arn   = "${var.ssl_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.app_lb_tg_backend.arn}"
  }
}

resource "aws_lb_listener" "app_lb_listener_frontend_pt443" {
  load_balancer_arn = "${aws_lb.app_load_balancer.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${var.ssl_arn}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.app_lb_tg_frontend.arn}"
  }
}

resource "aws_lb_listener" "app_lb_listener_frontend_pt80" {
  load_balancer_arn = "${aws_lb.app_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    # target_group_arn = "${aws_lb_target_group.app_lb_tg_frontend.arn}"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_route53_zone" "app_route_zone" {
  zone_id = "Z09251793R77P2RZ1JXPT"
  vpc_id = "${aws_vpc.app_vpc.id}"
}

resource "aws_route53_record" "dns_record" {
  zone_id = "Z09251793R77P2RZ1JXPT"
  name    = "prod.rhishikesh.me"
  type    = "A"
  alias {
    name                   = "${aws_lb.app_load_balancer.dns_name}"
    zone_id                = "${aws_lb.app_load_balancer.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_codedeploy_app" "app_codedeploy_webapp_name" {
  name = "csye6225-webapp"
}

resource "aws_codedeploy_deployment_group" "app_codedeploy_webapp_group" {
  app_name              = "${aws_codedeploy_app.app_codedeploy_webapp_name.name}"
  deployment_group_name = "csye6225-webapp-deployment"
  service_role_arn      = "${aws_iam_role.app_codedeploy_service_role.arn}"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  autoscaling_groups = ["${aws_autoscaling_group.app_autoscaling_group.name}"]
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "${var.vpc_name}_application_instance"
    }
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}


# ----------------- LAMDA FUNCTION -------------------------------------
resource "aws_iam_role" "app_role_sns_lamba" {
  name = "app_role_sns_lamba"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy"  "app_lamda_log_policy" {
  name = "app_lamda_log_policy"
  description = "Policy for Updating Lambda logs to CloudWatch"
  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement":[
      {
        "Action":[
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect":"Allow",
        "Resource":"arn:aws:logs:::*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "app_lamda_dynamodb_policy_attachment" {
	role = "${aws_iam_role.app_role_sns_lamba.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# resource "aws_iam_role_policy_attachment" "lambda_route53" {
# 	role = "${aws_iam_role.role_for_sns_lambda.name}"
# 	policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
# }

resource "aws_iam_role_policy_attachment" "app_lamda_sns_policy_attachment" {
	role = "${aws_iam_role.app_role_sns_lamba.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "app_lamda_ses_policy_attachment" {
	role = "${aws_iam_role.app_role_sns_lamba.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role_policy_attachment" "app_lamda_s3_policy_attachment" {
	role = "${aws_iam_role.app_role_sns_lamba.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "app_lamda_cloudwatch_logs_policy_attachment" {
	role = "${aws_iam_role.app_role_sns_lamba.name}"
	policy_arn = "${aws_iam_policy.app_lamda_log_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "app_lamda_basic_exe_role_attachment" {
  role = "${aws_iam_role.app_role_sns_lamba.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "app_lamda_dynamodb_exe_role_attachment" {
  role = "${aws_iam_role.app_role_sns_lamba.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

resource "aws_sns_topic" "app_sns_topic_des" {
	name = "sns_reset_password"
}

resource "aws_sns_topic_subscription" "app_sns_topic_subs" {
	topic_arn = "${aws_sns_topic.app_sns_topic_des.arn}"
	protocol = "lambda"
	endpoint = "${aws_lambda_function.app_lamda_email_func.arn}"
}

resource "aws_lambda_permission" "app_lamda_invoke_func_permission" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.app_lamda_email_func.function_name}"
  principal = "sns.amazonaws.com"
  source_arn = "${aws_sns_topic.app_sns_topic_des.arn}"
}

resource "aws_iam_role_policy_attachment" "app_codedeploy_service_role_sns_policy_attach" {
	role = "${aws_iam_role.app_codedeploy_ec2_host_service_role.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_lambda_function" "app_lamda_email_func" {
  filename = "lambda.zip"
  function_name = "LamdaEmailFunc"
  role = "${aws_iam_role.app_role_sns_lamba.arn}"
  handler = "email.handler"
  runtime = "nodejs12.x"
  memory_size = 512
  timeout = 25
  environment {
    variables = {
      aws_region = "${var.aws_region}"
    }
  }
}

resource "aws_iam_policy" "LambdaAccess" {
  name        = "LambdaAccess"
  description = "Lambda access policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:UpdateFunctionEventInvokeConfig",
                "lambda:TagResource",
                "lambda:UpdateEventSourceMapping",
                "lambda:InvokeFunction",
                "lambda:PublishLayerVersion",
                "lambda:DeleteProvisionedConcurrencyConfig",
                "lambda:UpdateFunctionConfiguration",
                "lambda:InvokeAsync",
                "lambda:CreateEventSourceMapping",
                "lambda:UntagResource",
                "lambda:PutFunctionConcurrency",
                "lambda:UpdateAlias",
                "lambda:UpdateFunctionCode",
                "lambda:DeleteLayerVersion",
                "lambda:PutProvisionedConcurrencyConfig",
                "lambda:DeleteAlias",
                "lambda:PutFunctionEventInvokeConfig",
                "lambda:DeleteFunctionEventInvokeConfig",
                "lambda:DeleteFunction",
                "lambda:PublishVersion",
                "lambda:DeleteFunctionConcurrency",
                "lambda:DeleteEventSourceMapping",
                "lambda:CreateAlias"
            ],
            "Resource": "arn:aws:lambda:${var.aws_region}:567826654401:function:LamdaEmailFunc"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "lambda_update_access" {
  user       = "${var.circleci_user}"
  policy_arn = "${aws_iam_policy.LambdaAccess.arn}"
}