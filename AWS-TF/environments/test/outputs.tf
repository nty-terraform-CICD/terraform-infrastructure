# 추후 생성될 EC2, DB 등을 위한 Output 확인
output "vpc_id" {
  value = module.network.vpc_id
}
