# ---------------------------------------------------------
# CREATE THE VPC
# ---------------------------------------------------------

resource "aws_vpc" "vpc" {

  cidr_block  = "${var.vpc_cidr}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.name_vpc}"
  }
}

# ---------------------------------------------------------
# public subnet
# ---------------------------------------------------------

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"

  cidr_block = "${var.public_ip}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.name_public_subnet}"
  }
}

# ---------------------------------------------------------
# private subnet
# ---------------------------------------------------------
resource "aws_subnet" "private_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"

  cidr_block = "${var.private_ip}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.name_private_subnet}"
  }
}

# ---------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# ---------------------------------------------------------
# NAT Gateway
# ---------------------------------------------------------

resource "aws_eip" "nat_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {

  allocation_id = "${aws_eip.nat_ip.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"

tags {
    Name = "${var.nat-gateway}"
  }
}

# ---------------------------------------------------------
# Public Table Route
# ---------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags {
    Name = "${var.name-pub-table}"
  }
}

# ---------------------------------------------------------
# Private Table Route
# ---------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags {
    Name = "${var.name-priv-table}"
  }
}
