variable "names" {
  type = list(string)
}

variable "public_masters" {
  type = list(string)
}
variable "private_masters" {
  type = list(string)
}

variable "vpc_id" {}
variable "vpc_natgw_id" {}
variable "subnet_id" {}

variable "ssh_key_id" {}
variable "ssh_key" {}

variable "ssl_certs" {}

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

