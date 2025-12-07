# 1. 보안 정책 정의 (CIDR 매핑 테이블)
# 이 부분은 모듈 관리자(보안팀)만 수정한다고 가정합니다.
locals {
  network_policies = {
    prod = {
      vpc_cidr        = "10.1.0.0/16"
      public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
      private_subnets = ["10.1.10.0/24", "10.1.11.0/24"]
      azs             = ["us-east-2a", "us-east-2c"]
    }
    test = {
      vpc_cidr        = "10.2.0.0/16"
      public_subnets  = ["10.2.1.0/24", "10.2.2.0/24"]
      private_subnets = ["10.2.10.0/24", "10.2.11.0/24"]
      azs             = ["us-west-2a", "us-west-2c"]
    }
  }

  # 사용자가 입력한 env_name에 맞는 설정을 자동으로 선택
  selected_config = local.network_policies[var.env_name]
}

# 1. VPC 생성
resource "aws_vpc" "vpc" {
  cidr_block           = local.selected_config.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.env_name}-vpc"
  }
}

# 2. Public Subnets 생성 (2개)
resource "aws_subnet" "public_subnet" {
  count             = length(local.selected_config.public_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.selected_config.public_subnets[count.index]
  availability_zone = local.selected_config.azs[count.index]

  map_public_ip_on_launch = true # Public Subnet 설정

  tags = {
    Name = "${var.env_name}-public-${count.index + 1}"
    Type = "Public"
  }
}

# 3. Private Subnets 생성 (2개)
resource "aws_subnet" "private_subnet" {
  count             = length(local.selected_config.private_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.selected_config.private_subnets[count.index]
  availability_zone = local.selected_config.azs[count.index]

  tags = {
    Name = "${var.env_name}-private-${count.index + 1}"
    Type = "Private"
  }
}

# 4. Internet Gateway (Public Subnet 통신용)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.env_name}-igw"
  }
}

# 5. Route Table (Public)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env_name}-public-rt"
  }
}

# 6. Route Table (Private)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    # NAT-GW ec2를 등록
  }

  tags = {
    Name = "${var.env_name}-private-rt"
  }
}

# 6. Route Table Association (Public Subnet 연결)
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# (참고) Private Subnet용 NAT Gateway는 비용 문제로 Test 환경에서는 제외할 수 있도록
# 모듈을 더 고도화하거나, Prod 환경에서만 별도로 추가하는 것이 좋습니다.

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
