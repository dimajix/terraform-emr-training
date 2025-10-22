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
  default = "emr-6.2.0"
}

variable "applications" {
  type = list(string)
  default = ["Spark", "Hadoop", "Pig", "Hue", "Zeppelin", "Hive", "HCatalog", "HBase", "Presto", "Tez", "ZooKeeper"]
}

variable "log_uri" {
}

variable "vpc_id" {
}

variable "vpc_natgw_id" {
}

variable "subnet_id" {
}

variable "edge_security_group_id" {
}

variable "ssh_key_ids" {
  type = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

