variable "common_tags" {
  type = map(string)
  default = {
    builtWith = "terraform"
    terraformGroup = "training-dmx"
  }
} 


module "vpc" {
  source = "./vpc"
  name  = "training-vpc"
  tags  = var.common_tags

  cidr = "10.200.0.0/16"
  private_subnets = ["10.200.1.0/24"]
  public_subnets  = ["10.200.101.0/24"]
  enable_nat_gateway = "false"
  enable_s3_endpoint = "true"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  azs      = var.aws_availability_zones
}


module "emr" {
  source = "./emr"
  tags   = var.common_tags

  # Configuration: Set the Route53 zone name
  proxy_domain = "training.dimajix-aws.net"
  # Configuration: Set the cluster names
  names = ["cl1","cl2","cl3","cl4","cl5","cl6"]
  # Configuration: Set the desired EMR release
  release = "emr-5.23.0"
  # Configuration: Set the desired EMR components
  applications = ["Spark","Hadoop","Hue","Zeppelin","Hive","Zookeeper"]
  # Configuration: Set the desired EC2 instance type for the master
  master_type = "m4.xlarge"
  master_ebs_size = "40"
  # Configuration: Set the desired EC2 instance type for the workers
  worker_type = "m4.2xlarge"
  worker_ebs_size = "40"
  worker_count = 1

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  ssh_key_ids = [aws_key_pair.deployer.id]
  
  # Configuration: Set the user name for basic auth
  proxy_user = "dimajix"
  # Configuration: Set the password for basic auth
  proxy_password = "dmx2018"
}


module route53 {
  source = "./route53"
  tags   = var.common_tags
  names = module.emr.names
  targets = module.emr.master_public_dns

  # Configuration: Set the Route53 zone to use
  zone_name = "training.dimajix-aws.net"
}

