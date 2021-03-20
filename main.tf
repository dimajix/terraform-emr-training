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
  version = "2.77.0"

  name  = "training-vpc"
  tags  = var.common_tags

  azs = var.aws_availability_zones
  cidr = "10.200.0.0/16"
  private_subnets = ["10.200.1.0/24"]
  public_subnets  = ["10.200.101.0/24"]
  enable_nat_gateway = "false"
  enable_s3_endpoint = "true"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
}



module "proxy" {
  source = "./proxy"
  tags   = var.common_tags
  names = ["kku", "cl1"] # module.emr.names
  targets = ["dimajix.de", "dimajix.de"] #module.emr.master_public_dns

  # Configure the domain
  proxy_domain = "training.dimajix-aws.net"  
  # Configuration: Set the user name for basic auth
  proxy_user = "dimajix"
  # Configuration: Set the password for basic auth
  proxy_password = "dmx2021"

  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
  ssh_key_id = aws_key_pair.deployer.id
  ssh_key = file("deployer-key")
  ssl_certfile = "ssl.cert"
  ssl_keyfile = "ssl.key"
}


module "route53" {
  source = "./route53"
  tags   = var.common_tags
  names = ["kku", "cl1"] # module.emr.names
  targets = [module.proxy.public_dns]

  # Configuration: Set the Route53 zone to use
  zone_name = "training.dimajix-aws.net"
}
