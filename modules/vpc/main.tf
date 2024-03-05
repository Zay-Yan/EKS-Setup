# modules/networking/main.tf
# resources: VPC, Subnets, IGW, NAT GW

# Create custom VPC that we will use for this lab
resource "aws_vpc" "lab-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Lab-vpc"
  }
}

# Create internet gateway - since this is custom vpc
resource "aws_internet_gateway" "lab-igw" {
  vpc_id = aws_vpc.lab-vpc.id
  tags = {
    Name = "IGW"
  }
}

# Create Elastic IPs for NAT gateways
resource "aws_eip" "lab_nat_eip_a" {
  tags = {
    Name = "NAT-GW_EIP_A"
  }
}

resource "aws_eip" "lab_nat_eip_b" {
  tags = {
    Name = "NAT-GW_EIP_B"
  }
}


# Create NAT gateways in public subnets

resource "aws_nat_gateway" "lab_nat_gateway_a" {
  allocation_id = aws_eip.lab_nat_eip_a.id
  subnet_id     = aws_subnet.lab-public-subnets-nat[0].id # Specify the public subnet where the NAT gateway should be created

  tags = {
    Name = "NAT-GW_ZA"
  }
}

resource "aws_nat_gateway" "lab_nat_gateway_b" {
  allocation_id = aws_eip.lab_nat_eip_b.id
  subnet_id     = aws_subnet.lab-public-subnets-nat[1].id # Specify the public subnet where the NAT gateway should be created

  tags = {
    Name = "NAT-GW_ZB"
  }
}

# Create public subnets

resource "aws_subnet" "lab-public-subnets-nat" {
  count                   = 3
  vpc_id                  = aws_vpc.lab-vpc.id
  cidr_block              = count.index == 0 ? "10.0.1.0/24" : count.index == 1 ? "10.0.2.0/24" : "10.0.3.0/24"
  availability_zone       = count.index == 0 ? var.az-a : count.index == 1 ? var.az-b : var.az-c
  map_public_ip_on_launch = true # Make both subnets public

  tags = {
    Name = "Public-Subnet-NAT-${element(["ZA", "ZB", "ZC"], count.index)}"
  }
}

# Create public ELB Subnets

resource "aws_subnet" "lab-public-subnets-elb" {
  count                   = 3
  vpc_id                  = aws_vpc.lab-vpc.id
  cidr_block              = count.index == 0 ? "10.0.4.0/24" : count.index == 1 ? "10.0.5.0/24" : "10.0.6.0/24"
  availability_zone       = count.index == 0 ? var.az-a : count.index == 1 ? var.az-b : var.az-c
  map_public_ip_on_launch = true # Make both subnets public

  tags = {
    Name = "Public-Subnet-ELB-${element(["ZA", "ZB", "ZC"], count.index)}"
  }
}


# Create private subnets

resource "aws_subnet" "lab-private-subnets-app" {
  count                   = 3
  vpc_id                  = aws_vpc.lab-vpc.id
  cidr_block              = count.index == 0 ? "10.0.7.0/24" : count.index == 1 ? "10.0.8.0/24" : "10.0.9.0/24"
  availability_zone       = count.index == 0 ? var.az-a : count.index == 1 ? var.az-b : var.az-c
  map_public_ip_on_launch = false # Make both subnets private

  tags = {
    Name = "Private-Subnet-APP-${element(["ZA", "ZB", "ZC"], count.index)}"
  }
}



# Create private subnets for rds
resource "aws_subnet" "lab-private-subnets-rds" {

  count                   = 3
  vpc_id                  = aws_vpc.lab-vpc.id
  cidr_block              = count.index == 0 ? "10.0.10.0/28" : count.index == 1 ? "10.0.11.0/28" : "10.0.12.0/28"
  availability_zone       = count.index == 0 ? var.az-a : count.index == 1 ? var.az-b : var.az-c
  map_public_ip_on_launch = false # Make both subnets private

  tags = {
    Name = "Private-Subnet-RDS-${element(["ZA", "ZB", "ZC"], count.index)}"
  }

}


# Create private subnets for EKS
resource "aws_subnet" "lab-private-subnets-eks" {

  count                   = 2
  vpc_id                  = aws_vpc.lab-vpc.id
  cidr_block              = count.index == 0 ? "10.0.13.0/28" : count.index == 1 ? "10.0.14.0/28"  "10.0.15.0/28"
  availability_zone       = count.index == 0 ? var.az-a : count.index == 1 ? var.az-b : var.az-c
  map_public_ip_on_launch = false # Make both subnets private

  tags = {
    Name = "Private-Subnet-EKS-${element(["ZA", "ZB", "ZC"], count.index)}"
  }

}


# Create route table for private subnetss - NAT for internet access
resource "aws_route_table" "private_route_table_app_a" {
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_nat_gateway_a.id
  }

  tags = {
    Name = "Private-Route-Table-APP-ZA"
  }

}

resource "aws_route_table" "private_route_table_app_b" {
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_nat_gateway_b.id
  }

  tags = {
    Name = "Private-Route-Table-APP-ZB"
  }

}


# Create route table for private subnetss - RDS for internet access
resource "aws_route_table" "private_route_table_rds_a" {
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_nat_gateway_a.id
  }

  tags = {
    Name = "Private-Route-Table-RDS-ZA"
  }

}

resource "aws_route_table" "private_route_table_rds_b" {
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_nat_gateway_b.id
  }

  tags = {
    Name = "Private-Route-Table-RDS-ZB"
  }

}




# Create route table for private subnetss - EKS for internet access
resource "aws_route_table" "private_route_table_eks_a" {
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_nat_gateway_a.id
  }

  tags = {
    Name = "Private-Route-Table-EKS-ZA"
  }

}

resource "aws_route_table" "private_route_table_eks_b" {
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_nat_gateway_b.id
  }

  tags = {
    Name = "Private-Route-Table-EKS-ZB"
  }

}



# Create route table for public subnets

resource "aws_route_table" "lab-public-route-table" {
  count  = 3
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab-igw.id
  }

  tags = {
    Name = "Public-Route-Table-${element(["ZA", "ZB"], count.index)}"
  }
}



# Associate private route table A with private subnet A - APP
resource "aws_route_table_association" "private_subnet_association_a" {
  subnet_id      = aws_subnet.lab-private-subnets-app[0].id
  route_table_id = aws_route_table.private_route_table_app_a.id
}

# Associate private route table B with private subnet B - APP
resource "aws_route_table_association" "private_subnet_association_b" {
  subnet_id      = aws_subnet.lab-private-subnets-app[1].id
  route_table_id = aws_route_table.private_route_table_app_b.id
}



###########

# Associate private route table A with private subnet A - RDS
resource "aws_route_table_association" "private_subnet_association_rds_a" {
  subnet_id      = aws_subnet.lab-private-subnets-rds[0].id
  route_table_id = aws_route_table.private_route_table_rds_a.id
}

# Associate private route table B with private subnet B - RDS
resource "aws_route_table_association" "private_subnet_association_rds_b" {
  subnet_id      = aws_subnet.lab-private-subnets-rds[1].id
  route_table_id = aws_route_table.private_route_table_rds_b.id
}


##########

# Associate private route table A with private subnet A - EKS
resource "aws_route_table_association" "private_subnet_association_eks_a" {
  subnet_id      = aws_subnet.lab-private-subnets-eks[0].id
  route_table_id = aws_route_table.private_route_table_eks_a.id
}

# Associate private route table B with private subnet B - EKS
resource "aws_route_table_association" "private_subnet_association_eks_b" {
  subnet_id      = aws_subnet.lab-private-subnets-eks[1].id
  route_table_id = aws_route_table.private_route_table_eks_b.id
}

# Associate private route table C with private subnet C - EKS

#########

# Associate public route table with public subnets NAT
resource "aws_route_table_association" "lab-public-subnet-nat-association" {
  count          = 3
  subnet_id      = aws_subnet.lab-public-subnets-nat[count.index].id
  route_table_id = aws_route_table.lab-public-route-table[count.index].id
}

# Associate public route table with public subnets ELB
resource "aws_route_table_association" "lab-public-subnet-elb-association" {
  count          = 3
  subnet_id      = aws_subnet.lab-public-subnets-elb[count.index].id
  route_table_id = aws_route_table.lab-public-route-table[count.index].id
}







