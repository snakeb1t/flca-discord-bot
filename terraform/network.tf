resource "aws_vpc" "flca" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = true

  tags = { Name = "custom-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.flca.id
  cidr_block              = "10.0.1.0/24"
  ipv6_cidr_block         = cidrsubnet(aws_vpc.flca.ipv6_cidr_block, 8, 1)
  availability_zone       = "us-east-1a"
  assign_ipv6_address_on_creation = true

  tags = { Name = "public-subnet-flca" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.flca.id
  cidr_block        = "10.0.10.0/24"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.flca.ipv6_cidr_block, 8, 2)
  availability_zone = "us-east-1a"
  assign_ipv6_address_on_creation = true

  tags = { Name = "private-subnet-flca" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.flca.id

  tags = { Name = "flca-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.flca.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }

# TODO: add local ipv6 route
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = { Name = "public-flca-route-table" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.flca.id

# TODO: add local ipv6 route
  route {
    cidr_block     = "10.0.0.0/16"
    gateway_id     = "local"
  }

  tags = { Name = "private-flca-route-table" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
