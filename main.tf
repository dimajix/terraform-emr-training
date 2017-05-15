variable "common_tags" {
  type = "map"
  default = {
    builtWith = "terraform"
    terraformGroup = "training-vvs"
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
#  names = ["training-kku", "training-uel", "training-ren", "training-fpo"]
  names = ["training-kku"]
  master_type = "m3.xlarge"
  worker_type = "m3.xlarge"
  worker_count = 2
  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = ["${module.vpc.public_subnets}"]
  ssh_key_ids = ["${aws_key_pair.deployer.id}"]
  tags   = "${var.common_tags}"
}

