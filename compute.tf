data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "web" {
  name_prefix   = "cloudathon-launch-template"
  image_id      = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  # Require IMDSv2 for instance metadata and role credentials.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Runs on first boot of instances launched from this template.
  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -Eeuo pipefail
    exec > >(tee -a /var/log/cloudathon-bootstrap.log) 2>&1
    trap 'status=$?; echo "ERROR: bootstrap failed at line $LINENO (exit $status)" >&2; exit "$status"' ERR

    # Retry transient failures up to five times, with increasing delays.
    retry() {
      local attempt=1
      local delay=10
      local status
      while true; do
        if "$@"; then
          return 0
        else
          status=$?
        fi
        if (( attempt >= 5 )); then
          echo "ERROR: $1 failed after $attempt attempts (exit $status)" >&2
          return "$status"
        fi
        echo "WARN: $1 failed on attempt $attempt; retrying in $delay seconds" >&2
        sleep "$delay"
        attempt=$((attempt + 1))
        delay=$((delay * 2))
      done
    }

    # AL2023 normally includes the agent; install it if missing.
    if ! rpm -q amazon-ssm-agent; then
      retry dnf install -y https://s3.us-east-2.amazonaws.com/amazon-ssm-us-east-2/latest/linux_amd64/amazon-ssm-agent.rpm
    fi
    retry systemctl enable --now amazon-ssm-agent
    retry systemctl is-active --quiet amazon-ssm-agent

    retry dnf install -y httpd
    echo '<h1>Cloudathon web server</h1>' > /var/www/html/index.html
    retry systemctl enable --now httpd
    retry systemctl is-active --quiet httpd
    retry curl --fail --silent --show-error --max-time 10 http://127.0.0.1/
    echo "Bootstrap completed successfully"
  USERDATA
  )

  depends_on = [aws_iam_role_policy_attachment.ec2_ssm]
}

resource "aws_lb" "web" {
  name               = "cloudathon-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

resource "aws_lb_target_group" "web" {
  name        = "cloudathon-web-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "cloudathon-web-asg"
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4
  default_instance_warmup   = 600
  health_check_type         = "ELB"
  health_check_grace_period = 900
  vpc_zone_identifier       = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  target_group_arns         = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  tag {
    key                 = "Name"
    value               = "cloudathon-web"
    propagate_at_launch = true
  }

  # Roll out launch-template updates while retaining healthy capacity.
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 150
      instance_warmup        = 600
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  depends_on = [
    aws_lb_listener.http,
    aws_route_table_association.private_az1,
    aws_route_table_association.private_az2,
    aws_route_table_association.public_az1,
    aws_route_table_association.public_az2,
    aws_vpc_security_group_ingress_rule.internet_to_alb_http,
    aws_vpc_security_group_egress_rule.alb_to_web_http,
    aws_vpc_security_group_ingress_rule.alb_to_web_http,
    aws_vpc_security_group_egress_rule.web_outbound,
  ]
}

resource "aws_autoscaling_policy" "web_requests" {
  name                   = "cloudathon-web-requests"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.web.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }

    # Starting threshold: requests per target per minute; tune after load testing.
    target_value = 1000
  }
}

output "website_url" {
  description = "HTTP address of the application load balancer"
  value       = "http://${aws_lb.web.dns_name}"
}
