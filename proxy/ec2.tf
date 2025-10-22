resource "aws_instance" "proxy" {
  depends_on = [
    var.vpc_natgw_id
  ]
  tags = merge( { "Name" = "training-emr-proxy" }, var.tags )

  # ami = "ami-05c26ae4789875080"
  # ami = "ami-0bdbe51a2e8070ff2"
  ami = "ami-04e601abe3e1a910f"
  instance_type = "c5.xlarge"
  key_name = var.ssh_key_id

  root_block_device {
    volume_type = "gp2"
    volume_size = 80
  }

  iam_instance_profile   = aws_iam_instance_profile.proxy.name

  vpc_security_group_ids = [ aws_security_group.proxy.id ]
  subnet_id              = var.subnet_id
  associate_public_ip_address = true

  connection {
    host     = self.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = var.ssh_key
  }
  provisioner "file" {
    source      = "proxy/provisioner"
    destination = "/home/ubuntu"
  }
  provisioner "file" {
    source      = var.ssl_certs
    destination = "/home/ubuntu/certs/"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 15",
      "cloud-init status --wait"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/provisioner",
      "sh /home/ubuntu/provisioner/provision.sh -d ${var.proxy_domain} -u ${var.proxy_user} -p ${var.proxy_password} -C /home/ubuntu/certs --pubic-masters ${join(",",var.public_masters)} --private-masters ${join(",",var.private_masters)} --names ${join(",",var.names)}"
    ]
  }
}


# IAM Role for EC2 Instance Profile
resource "aws_iam_role" "proxy" {
  name = "training-emr-proxy"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "proxy" {
  name = "training-emr-proxy-profile"
  role = aws_iam_role.proxy.name
}

resource "aws_iam_role_policy" "proxy" {
  name = "training-emr-proxy-policy"
  role = aws_iam_role.proxy.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "cloudwatch:*",
            "ec2:Describe*",
            "rds:Describe*",
            "eks:Describe*"
        ]
    }]
}
EOF
}

