# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE CLASIC LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_elb" "test" {
  name               = "foobar-terraform-elb"
  #availability_zones = ["us-west-1a", "us-west-1b"]
  availability_zones   = ["${var.region}"]
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
