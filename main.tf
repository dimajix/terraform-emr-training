variable "common_tags" {
  type = "map"
  default = {
    builtWith = "terraform"
    terraformGroup = "training-dmx"
  }
} 


module "vpc" {
  source = "./vpc"
  name = "training-vpc"

  cidr = "10.200.0.0/16"
  private_subnets = ["10.200.1.0/24"]
  public_subnets  = ["10.200.101.0/24"]
  enable_nat_gateway = "false"
  enable_s3_endpoint = "true"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  azs      = "${var.aws_availability_zones}"
  tags     = "${var.common_tags}"
}


module "emr" {
  source = "./emr"
  names = ["training-kku"]
  applications = ["Spark","Hadoop","Hue","Zeppelin","Hive","ZooKeeper", "HBase"]
  master_type = "m3.xlarge"
  worker_type = "m3.xlarge"
  worker_count = 2
  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = ["${module.vpc.public_subnets}"]
  ssh_key_ids = ["${aws_key_pair.deployer.id}"]
  proxy_domain = "training.dimajix-aws.net"
  proxy_user = "dimajix-training"
  proxy_password = "dmx2018"
  tags   = "${var.common_tags}"
}


module route53 {
  source = "./route53"
  names = ["kku"]
  targets = ["${module.emr.master_public_dns}"]
  zone_name = "training.dimajix-aws.net"
  tags   = "${var.common_tags}"
}

