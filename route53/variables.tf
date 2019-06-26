variable "names" {
  type = list(string)
  default = ["emr"]
}

variable "targets" {
  type = list(string)
  default = []
}

variable "zone_name" {
  default = "aws.dimajix.net"
}

variable "tags" {
  type    = map(string)
  default = {}
}

