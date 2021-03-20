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

