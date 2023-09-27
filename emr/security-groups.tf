resource "aws_security_group" "master" {
  name        = "training_emr_master"
  description = "Allow inbound ssh"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags)
}

resource "aws_security_group_rule" "master_ingress_self" {
  security_group_id = aws_security_group.master.id
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  self        = true
}

resource "aws_security_group_rule" "master_ingress_slave" {
  security_group_id = aws_security_group.master.id
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  source_security_group_id = aws_security_group.slave.id
}

resource "aws_security_group_rule" "master_ingress_ssh" {
  security_group_id = aws_security_group.master.id
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master_ingress_edge" {
  security_group_id = aws_security_group.master.id
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  source_security_group_id = var.edge_security_group_id
}

resource "aws_security_group_rule" "master_egress_allow_all" {
  security_group_id = aws_security_group.master.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "master_ingress_service" {
  security_group_id = aws_security_group.master.id
  type        = "ingress"
  from_port   = 8443
  to_port     = 8443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.service.id
}

resource "aws_security_group_rule" "master_egress_service" {
  security_group_id = aws_security_group.master.id
  type        = "egress"
  from_port   = 9443
  to_port     = 9443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.service.id
}

resource "aws_security_group_rule" "master_egress_service_http" {
  security_group_id = aws_security_group.master.id
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  source_security_group_id = aws_security_group.service.id
}

resource "aws_security_group_rule" "master_egress_service_https" {
  security_group_id = aws_security_group.master.id
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.service.id
}



resource "aws_security_group" "slave" {
  name        = "training_emr_slave"
  description = "Allow inbound ssh"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags)
}

resource "aws_security_group_rule" "slave_ingress_self" {
  security_group_id = aws_security_group.slave.id
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  self        = true
}

resource "aws_security_group_rule" "slave_ingress_master" {
  security_group_id = aws_security_group.slave.id
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "slave_ingress_ssh" {
  security_group_id = aws_security_group.slave.id
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "slave_egress_allow_all" {
  security_group_id = aws_security_group.slave.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "slave_ingress_service" {
  security_group_id = aws_security_group.slave.id
  type        = "ingress"
  from_port   = 8443
  to_port     = 8443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.service.id
}

resource "aws_security_group_rule" "slave_egress_service_http" {
  security_group_id = aws_security_group.slave.id
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  source_security_group_id = aws_security_group.service.id
}

resource "aws_security_group_rule" "slave_egress_service_https" {
  security_group_id = aws_security_group.slave.id
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.service.id
}


resource "aws_security_group" "service" {
  name        = "training_emr_service"
  description = "Allow accessing services"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags)
}

resource "aws_security_group_rule" "service_ingress_self" {
  security_group_id = aws_security_group.service.id
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  self        = true
}

resource "aws_security_group_rule" "service_ingress_master" {
  security_group_id = aws_security_group.service.id
  type        = "ingress"
  from_port   = 9443
  to_port     = 9443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "service_egress_master" {
  security_group_id = aws_security_group.service.id
  type        = "egress"
  from_port   = 8443
  to_port     = 8443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "service_egress_slave" {
  security_group_id = aws_security_group.service.id
  type        = "egress"
  from_port   = 8443
  to_port     = 8443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.slave.id
}

