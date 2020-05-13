data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

resource "aws_vpc" "mod" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags = merge(
    var.tags,
    {
      "name" = format("%s", var.name)
    },
  )
}

resource "aws_internet_gateway" "mod" {
  vpc_id = aws_vpc.mod.id
  tags = merge(
    var.tags,
    {
      "name" = format("%s-igw", var.name)
    },
  )
}

resource "aws_route_table" "public" {
  vpc_id           = aws_vpc.mod.id
  propagating_vgws = var.public_propagating_vgws
  tags = merge(
    var.tags,
    {
      "name" = format("%s-rt-public", var.name)
    },
  )
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mod.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.natgw.*.id, count.index)
  count = length(var.private_subnets) * lookup({"true" = 1}, var.enable_nat_gateway, 0)
}

resource "aws_route_table" "private" {
  vpc_id           = aws_vpc.mod.id
  propagating_vgws = var.private_propagating_vgws
  count            = length(var.private_subnets)
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-rt-private-%s", var.name, element(var.azs, count.index))
    },
  )
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.mod.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.azs, count.index)
  count             = length(var.private_subnets)
  tags = merge(
    var.tags,
    {
      "name" = format(
        "%s-subnet-private-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
  )
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.mod.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = element(var.azs, count.index)
  count             = length(var.public_subnets)
  tags = merge(
    var.tags,
    {
      "name" = format(
        "%s-subnet-public-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
  )

  map_public_ip_on_launch = var.map_public_ip_on_launch
}

resource "aws_eip" "nateip" {
  vpc = true
  count = length(var.private_subnets) * lookup({"true" = 1}, var.enable_nat_gateway, 0)
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = element(aws_eip.nateip.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  count = length(var.private_subnets) * lookup({"true" = 1}, var.enable_nat_gateway, 0)

  depends_on = [aws_internet_gateway.mod]
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Create a VPC endpoint
resource "aws_vpc_endpoint" "s3ep" {
  vpc_id = aws_vpc.mod.id
  count = lookup({"true" = 1}, var.enable_s3_endpoint, 0)
  service_name = data.aws_vpc_endpoint_service.s3.service_name
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = length(var.private_subnets) * lookup({"true" = 1}, var.enable_s3_endpoint, 0)
  vpc_endpoint_id = aws_vpc_endpoint.s3ep[0].id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count = length(var.public_subnets) * lookup({"true" = 1}, var.enable_s3_endpoint, 0)
  vpc_endpoint_id = aws_vpc_endpoint.s3ep[0].id
  route_table_id  = element(aws_route_table.public.*.id, count.index)
}

