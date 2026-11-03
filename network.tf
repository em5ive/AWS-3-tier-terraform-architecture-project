# Isolated database subnets: no internet or NAT default route.
resource "aws_subnet" "db_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "cloudathon-db-az1"
  }
}

resource "aws_subnet" "db_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.80.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "cloudathon-db-az2"
  }
}

# AWS automatically supplies the VPC-local route.
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cloudathon-db-rt"
  }
}

resource "aws_route_table_association" "db_az1" {
  subnet_id      = aws_subnet.db_az1.id
  route_table_id = aws_route_table.database.id
}

resource "aws_route_table_association" "db_az2" {
  subnet_id      = aws_subnet.db_az2.id
  route_table_id = aws_route_table.database.id
}

resource "aws_vpc" "main" {

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cloudathon-vpc"
  }
}

# public subnets
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudathon-public-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {

    Name = "cloudathon-public-az2"
  }

}

#igw

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cloudathon-igw"
  }

}
# public route table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id

  }

  tags = {
    Name = "cloudathon-public-rt"
  }
}



#route table associations(public)

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id

}


#private subnets

resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.32.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "cloudathon-priv-az1"
  }

}
resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.48.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "cloudathon-priv-az2"
  }

}


#nat gateway

resource "aws_eip" "nat1" {

  domain = "vpc"

  tags = {

    Name = "az1-nat-eip"
  }
}

resource "aws_eip" "nat2" {

  domain = "vpc"

  tags = {

    Name = "az2-nat-eip"
  }
}

#nat eips
resource "aws_nat_gateway" "az1-nat" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "az1-nat"
  }

}


resource "aws_nat_gateway" "az2-nat" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public_az2.id

  tags = {
    Name = "az2-nat"
  }

}

# private route table

resource "aws_route_table" "private-az1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1-nat.id
  }



  tags = {
    Name = "cloudathon-private-az1-rt"
  }
}

resource "aws_route_table" "private-az2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az2-nat.id
  }



  tags = {
    Name = "cloudathon-private-az2-rt"
  }
}

#route table associations(private)

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private-az1.id

}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private-az2.id

}

