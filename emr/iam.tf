# IAM role for EMR Service
resource "aws_iam_role" "training_emr_service_role" {
  name = "training_emr_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "training_emr_service_policy" {
  name = "training_emr_service_policy"
  role = aws_iam_role.training_emr_service_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CancelSpotInstanceRequests",
            "ec2:CreateNetworkInterface",
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:DeleteNetworkInterface",
            "ec2:DeleteSecurityGroup",
            "ec2:DeleteTags",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeInstances",
            "ec2:DescribeKeyPairs",
            "ec2:DescribeNetworkAcls",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribePrefixLists",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSpotInstanceRequests",
            "ec2:DescribeSpotPriceHistory",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcEndpoints",
            "ec2:DescribeVpcEndpointServices",
            "ec2:DescribeVpcs",
            "ec2:DetachNetworkInterface",
            "ec2:ModifyImageAttribute",
            "ec2:ModifyInstanceAttribute",
            "ec2:RequestSpotInstances",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:RunInstances",
            "ec2:TerminateInstances",
            "ec2:DeleteVolume",
            "ec2:DescribeVolumeStatus",
            "ec2:DescribeVolumes",
            "ec2:DetachVolume",
            "iam:GetRole",
            "iam:GetRolePolicy",
            "iam:ListInstanceProfiles",
            "iam:ListRolePolicies",
            "iam:PassRole",
            "s3:CreateBucket",
            "s3:Get*",
            "s3:List*",
            "sdb:BatchPutAttributes",
            "sdb:Select",
            "sqs:CreateQueue",
            "sqs:Delete*",
            "sqs:GetQueue*",
            "sqs:PurgeQueue",
            "sqs:ReceiveMessage",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:DeleteAlarms",
            "application-autoscaling:RegisterScalableTarget",
            "application-autoscaling:DeregisterScalableTarget",
            "application-autoscaling:PutScalingPolicy",
            "application-autoscaling:DeleteScalingPolicy",
            "application-autoscaling:Describe*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": "iam:CreateServiceLinkedRole",
        "Resource": "arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot*",
        "Condition": {
            "StringLike": {
                "iam:AWSServiceName": "spot.amazonaws.com"
            }
        }
    }]
}
EOF

}

# IAM Role for EC2 Instance Profile
resource "aws_iam_role" "training_ec2_role" {
name = "training_ec2_role"

assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "training_ec2_profile" {
name = "training_ec2_profile"
role = aws_iam_role.training_ec2_role.name
}

resource "aws_iam_role_policy" "training_ec2_policy" {
name = "training_ec2_policy"
role = aws_iam_role.training_ec2_role.id

policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "cloudwatch:*",
            "ec2:Describe*",
            "elasticmapreduce:Describe*",
            "elasticmapreduce:ListBootstrapActions",
            "elasticmapreduce:ListClusters",
            "elasticmapreduce:ListInstanceGroups",
            "elasticmapreduce:ListInstances",
            "elasticmapreduce:ListSteps",
            "rds:Describe*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListAllMyBuckets"
        ],
        "Resource": [
            "arn:aws:s3:::*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetBucketLocation",
            "s3:ListBucket"
        ],
        "Resource": [
            "arn:aws:s3:::dimajix-training"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject"
        ],
        "Resource": [
            "arn:aws:s3:::dimajix-training/*"
        ]
    }]
}
EOF

}

