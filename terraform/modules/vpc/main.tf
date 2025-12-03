variable "project" { type = string }

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project}-vpc" }
}

data "aws_availability_zones" "available" { state = "available" }

resource "aws_subnet" "public" {
  for_each = { for i, az in data.aws_availability_zones.available.names : i => az if i < 2 }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, tonumber(each.key))
  availability_zone       = each.value
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each = { for i, az in data.aws_availability_zones.available.names : i => az if i < 2 }
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, 100 + tonumber(each.key))
  availability_zone = each.value
  tags = { Name = "${var.project}-private-${each.value}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project}-igw" }
}

# NAT 
resource "aws_eip" "nat" { domain = "vpc" }
locals { nat_subnet_id = values(aws_subnet.public)[0].id }

# Attach NAT to the first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags = { Name = "${var.project}-nat" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route { 
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id 
    }
  tags = { 
    Name = "${var.project}-rt-public" 
    }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "${var.project}-private-rt" }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}


output "vpc_id"             { value = aws_vpc.this.id }
output "public_subnet_ids"  { value = [for s in aws_subnet.public  : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }