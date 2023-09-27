variable "common_tags" {
  type = map(string)
  default = {
    builtWith = "terraform"
    terraformGroup = "training-dmx"
  }
}

resource "aws_key_pair" "deployer" {
  key_name = "training-dmx"
  public_key = file("deployer-key.pub")
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name  = "training-vpc"
  tags  = var.common_tags

  azs = var.aws_availability_zones
  cidr = "10.200.0.0/16"
  private_subnets = ["10.200.1.0/24"]
  public_subnets  = ["10.200.101.0/24"]
  enable_nat_gateway = "true"
  single_nat_gateway = "false"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
}


module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.1.2"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "training-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      service = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags  = var.common_tags
    }
  }

  tags  = var.common_tags
}


module "emr" {
  source = "./emr"
  tags   = var.common_tags

  # Configuration: Set the cluster names
  names = ["kku"]
  #names = ["cl1","kku"]
  # Configuration: Set the desired EMR release
  release = "emr-6.8.0"
  # Configuration: Set the desired EMR components
  applications = ["Spark","Hadoop","Hue","Zeppelin","Hive","Zookeeper"]
  # Configuration: Set the desired EC2 instance type for the master
  # Refer to https://aws.amazon.com/de/ec2/spot/pricing/ for spot pricing
  master_type = "m5.xlarge"
  master_ebs_size = "60"
  master_bid_price = "" # 0.30
  # Configuration: Set the desired EC2 instance type for the workers
  worker_type = "m5.xlarge"
  worker_ebs_size = "120"
  worker_bid_price = "" # 0.60
  worker_count = 1
  # Setup logging
  log_uri = "s3://dimajix-logs/training/emr"

  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]
  edge_security_group_id = module.proxy.security_group_id
  ssh_key_ids = [aws_key_pair.deployer.id]
}


module "proxy" {
  source = "./proxy"
  tags   = var.common_tags
  names = module.emr.names
  public_masters = module.emr.master_public_dns
  private_masters = module.emr.master_private_dns

  # Configure the domain
  proxy_domain = "training.dimajix-aws.net"  
  # Configuration: Set the user name for basic auth
  proxy_user = "destatis"
  # Configuration: Set the password for basic auth
  proxy_password = "dmx2023"

  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
  ssh_key_id = aws_key_pair.deployer.id
  ssh_key = file("deployer-key")
  ssl_certs = "certs"
}


module "route53" {
  source = "./route53"
  tags   = var.common_tags
  names = module.emr.names
  targets = [module.proxy.public_dns]

  # Configuration: Set the Route53 zone to use
  zone_name = "training.dimajix-aws.net"
}

