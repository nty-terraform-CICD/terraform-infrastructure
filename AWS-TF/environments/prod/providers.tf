terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
# Provider 설정: 서울 리전
provider "aws" {
  region = "us-east-2"
}
