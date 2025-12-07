terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  backend "s3" {
    bucket         = "nty-terraform-state-prod"
    key            = "terraform/terraform.tfstate" # 수정됨: S3 내 파일 저장 경로
    region         = "us-east-2"                   # 수정됨: 시나리오에 맞춰 버지니아로 변경 (버킷도 이 리전에 있어야 함)
    encrypt        = true
    dynamodb_table = "nty-terraform-lock-prod"
    profile        = "developer" # 추가됨: Step 3에서 등록한 프로필 사용
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "developer" # 이 Provider는 developer 권한으로 실행됨
}

module "network" {
  source   = "../../modules/network"
  env_name = "prod" # 수정됨: prod로 변경1234
}
