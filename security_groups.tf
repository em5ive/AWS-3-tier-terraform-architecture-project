resource "aws_security_group" "alb" {
  name        = "cloudathon-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "cloudathon-alb-sg"
  }

}

resource "aws_security_group" "web" {
  name        = "cloudathon-web-sg"
  description = "Allow ALB traffic to compute"
  vpc_id      = aws_vpc.main.id

}

resource "aws_security_group" "database" {
  name        = "database"
  description = "Allow MySQL connections from web servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "database"
  }
}

resource "aws_vpc_security_group_ingress_rule" "internet_to_alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from Internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web_http" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP to web compute"
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}


# Database access is restricted to the web security group.
# No database outbound rules are defined.
# Replies to allowed inbound connections are automatically permitted.

resource "aws_vpc_security_group_ingress_rule" "web_to_database" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.web.id
  description                  = "MySQL from web security group only"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_web_http" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "web_outbound" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
