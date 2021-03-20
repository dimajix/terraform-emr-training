resource "aws_security_group" "proxy" {
  name        = "training_emr_proxy"
  description = "Allow inbound ssh"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags)
}

resource "aws_security_group_rule" "proxy_ingress_self" {
  security_group_id = aws_security_group.proxy.id
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  self        = true
}

resource "aws_security_group_rule" "proxy_ingress_ssh" {
  security_group_id = aws_security_group.proxy.id
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "proxy_ingress_http" {
  security_group_id = aws_security_group.proxy.id
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "proxy_ingress_https" {
  security_group_id = aws_security_group.proxy.id
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "proxy_egress_allow_all" {
  security_group_id = aws_security_group.proxy.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks = [ "0.0.0.0/0" ]
}

