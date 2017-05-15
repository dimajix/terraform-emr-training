variable "names" { default=["emr-cluster"] }
variable "worker_count" { default=2 }
variable "worker_type" { default="m3.xlarge" }
variable "master_type" { default="m3.xlarge" }
variable "release" { default = "emr-5.5.0" }
variable "applications" { default = ["Spark","Hadoop","Pig","Hue","Zeppelin","Hive","HCatalog","Presto","Tez","ZooKeeper"] }
variable "vpc_id" { }
variable "subnet_ids" { default=[] }
variable "ssh_key_ids" { default=[] }
variable "tags" { type="map" default={} }

