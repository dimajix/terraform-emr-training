data "aws_route53_zone" "emr" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_route53_record" "top" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = element(var.names, count.index)
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

resource "aws_route53_record" "rm" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = "rm.${element(var.names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

resource "aws_route53_record" "nn" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = "nn.${element(var.names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

resource "aws_route53_record" "ap" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = "ap.${element(var.names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

resource "aws_route53_record" "zeppelin" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = "zeppelin.${element(var.names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

resource "aws_route53_record" "jupyter" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = "jupyter.${element(var.names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

resource "aws_route53_record" "hue" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = "hue.${element(var.names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

resource "aws_route53_record" "hbase" {
  count   = length(var.names)
  zone_id = data.aws_route53_zone.emr.zone_id
  name    = "hbase.${element(var.names, count.index)}"
  type    = "CNAME"
  ttl     = "300"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.targets, count.index)]
}

