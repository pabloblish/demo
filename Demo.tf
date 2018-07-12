# 03-autoscaling.tf
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE CLASIC LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_elb" "test" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-west-1a", "us-west-1b"]
  security_groups        = ["${aws_security_group.load_balancer.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  tags {
    Name = "foobar-terraform-elb.test"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE CLASIC LAUNCH CONFIGURATION AND AUTO SCALING GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_configuration" "as_conf" {
  image_id              = "${var.image_id}"
  instance_type = "${var.instance_type}"
  key_name              = "${var.key_name}"
  security_groups = ["${aws_security_group.web.id}"]

  user_data = "${file("./script/app-user-data.sh")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bar" {
  name                 = "terraform-asg-example"
  launch_configuration = "${aws_launch_configuration.as_conf.name}"
  min_size             = 2
  max_size             = 2
  desired_capacity     = 1
  availability_zones   = ["us-west-1a", "us-west-1b"]
  load_balancers           = ["${aws_elb.test.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

# 04-rds.tf.bkp
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE DATABASE TIER
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_db_instance" "default" {
  allocated_storage    = "${var.allocated_storage}"
  storage_type         = "${var.storage_type}"
  engine               = "${var.engine}"
  engine_version       = "${var.engine_version}"
  instance_class       = "${var.instance_class}"
  name                 = "${var.name}"
  username             = "${var.username}"
  password             = "${var.password}"
  port                             = "${var.port}"
  parameter_group_name = "default.mysql5.6"
  vpc_security_group_ids = ["${aws_security_group.database.id}"]
}

# 05-security_groups.tf
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "load_balancer" {
  name        = "Load_Balancer"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

  #tags = {
    #Name        = "sg-elb-xport"
    #Project     = "xport"
  #}
}

# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name = "terraform-web"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    security_groups = ["${aws_security_group.load_balancer.id}"]
  }
  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "application" {
  name = "terraform-application"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "9043"
    to_port = "9043"
    protocol = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }
 ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "database" {
  name = "terraform-db-instance"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = "9043"
    to_port = "9043"
    protocol = "tcp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#  06-variables.tf
# ---------------------------------------------------------------
# ENVIRONMENT VARIABLES
# ---------------------------------------------------------------

variable "allocated_storage" {
        default = 10
}

variable "storage_type" {
        default = "gp2"
}

variable "engine" {
        default = "mysql"
}

variable "engine_version" {
        default = "5.6.39"
}

variable "instance_class" {
        default = "db.t2.micro"
}

variable "name" {
        default = "mydb"
}

variable "username" {
        default = "admin"
}

variable "password" {
        default = "t3mp0ral"
}

variable "port" {
        default = 3306
}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}
variable "vpc_id" {
        default = "vpc-3eff8559"
}

variable "image_id" {
  default = "ami-25110f45"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "MyKeyPair"
}

#  07-vpc.tf.bkp
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

# 08-var-vpc.tf
variable "name_vpc" {
        default = "AWS VPC"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
}

variable "public_ip" {
        default = "10.0.10.0/24"
}

variable "private_ip" {
        default = "10.0.20.0/24"
}

variable "vpc_name" {
        default = "vpc-terraform"
}

variable "environment" {
        default = "test"
}

variable "name_public_subnet" {
        default = "Public Subnet"
}

variable "name_private_subnet" {
        default = "Pivate Subnet"
}

variable "nat-gateway" {
        default = "Nat Gateway"
}

variable "name-pub-table" {
        default = "Public-Route-Table"
}

variable "name-priv-table" {
        default = "Private-Route-Table"
}

