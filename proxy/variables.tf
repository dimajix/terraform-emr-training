variable "names" {
  type = list(string)
}

variable "targets" {
  type = list(string)
}

variable "vpc_id" {
}

variable "subnet_id" {
}

variable "ssh_key_id" {
}

variable "ssh_key_file" {
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

