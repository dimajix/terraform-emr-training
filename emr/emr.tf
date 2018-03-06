resource "aws_emr_cluster" "cluster" {
  count         = "${length(var.names)}"
  name          = "${element(var.names, count.index)}"
  release_label = "${var.release}"
  applications  = "${concat(var.applications)}"

  ec2_attributes {
    subnet_id = "${element(var.subnet_ids, count.index)}"
    key_name = "${element(var.ssh_key_ids, count.index)}"
    emr_managed_master_security_group = "${aws_security_group.master.id}"
    emr_managed_slave_security_group = "${aws_security_group.slave.id}"
    # additional_master_security_groups = "${aws_security_group.allow_ssh.id}"
    instance_profile = "${aws_iam_instance_profile.training_ec2_profile.arn}"
  }

  ebs_root_volume_size = "12"
  master_instance_type = "${var.master_type}"
  core_instance_type   = "${var.worker_type}"
  core_instance_count  = "${var.worker_count}"

  tags = "${merge(var.tags, map("name", element(var.names, count.index)))}"

  # configurations = "test-fixtures/emr_configurations.json"

  service_role = "${aws_iam_role.training_emr_role.arn}"

  depends_on = ["aws_security_group.master","aws_security_group.slave"]

  bootstrap_action = [
    {
      path = "s3://dimajix-training/scripts/aws/install-jupyter-5.0.1.sh"
      name = "install-jupyter"
    },
    {
      path = "s3://dimajix-training/scripts/aws/install-reverse-proxy.sh"
      name = "install-reverse-proxy"
      args = ["-d", "${element(var.names, count.index)}.${var.proxy_domain}", "-u", "${var.proxy_user}", "-p", "${var.proxy_password}"]
    }
  ]
}

