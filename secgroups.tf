# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "load_balancer" {
  name        = "Load_Balancer"
  description = "Allow HTTP inbound traffic"
  #vpc_id      = "${var.vpc_id}"
  vpc_id      = "${aws_vpc.vpc.id}"

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
# Web Service Security Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name = "terraform-web"
  #vpc_id = "${var.vpc_id}"
  vpc_id      = "${aws_vpc.vpc.id}"

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
# Application Security Group 
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "application" {
  name = "terraform-application"
  #vpc_id = "${var.vpc_id}"
  vpc_id      = "${aws_vpc.vpc.id}"

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
# Database Security Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "database" {
  name = "terraform-db-instance"
  #vpc_id = "${var.vpc_id}"
  vpc_id      = "${aws_vpc.vpc.id}"
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
