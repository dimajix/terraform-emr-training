variable "names" {
  type = list(string)
  default = ["emr-cluster"]
}

variable "worker_count" {
  default = 2
}

variable "worker_type" {
  default = "m3.xlarge"
}

variable "worker_bid_price" {
  default = "0.30"
}

variable "worker_ebs_size" {
  default = "80"
}

variable "master_type" {
  default = "m3.xlarge"
}

variable "master_bid_price" {
  default = "0.30"
}

variable "master_ebs_size" {
  default = "80"
}

variable "release" {
  default = "emr-5.24.0"
}

variable "applications" {
  type = list(string)
  default = ["Spark", "Hadoop", "Pig", "Hue", "Zeppelin", "Hive", "HCatalog", "HBase", "Presto", "Tez", "ZooKeeper"]
}

variable "vpc_id" {
}

variable "subnet_ids" {
  type = list(string)
  default = []
}

variable "ssh_key_ids" {
  type = list(string)
  default = []
}

variable "proxy_domain" {
  default = "training.dimajix-aws.net"
}

variable "proxy_user" {
  default = "user"
}

variable "proxy_password" {
  default = "password"
}

variable "tags" {
  type    = map(string)
  default = {}
}

