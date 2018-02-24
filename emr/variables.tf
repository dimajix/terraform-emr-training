variable "names" { default=["emr-cluster"] }
variable "worker_count" { default=2 }
variable "worker_type" { default="m3.xlarge" }
variable "master_type" { default="m3.xlarge" }
variable "release" { default = "emr-5.12.0" }
variable "applications" { default = ["Spark","Hadoop","Pig","Hue","Zeppelin","Hive","HCatalog","HBase","Presto","Tez","ZooKeeper"] }
variable "vpc_id" { }
variable "subnet_ids" { default=[] }
variable "ssh_key_ids" { default=[] }
variable "proxy_domain" { default="training.dimajix-aws.net" }
variable "proxy_user" { default="user" }
variable "proxy_password" { default="password" }
variable "tags" { type="map" default={} }

