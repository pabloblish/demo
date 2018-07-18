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
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  availability_zones   = ["us-west-1a", "us-west-1b", "us-east-1a", "us-east-1b"]
  load_balancers           = ["${aws_elb.test.id}"]

  lifecycle {
    create_before_destroy = true
  }
}
