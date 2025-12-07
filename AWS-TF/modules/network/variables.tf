# modules/network/variables.tf

variable "env_name" {
  description = "배포할 환경의 이름 (보안 정책에 의해 prod 또는 test만 허용)"
  type        = string

  validation {
    condition     = contains(["prod", "test"], var.env_name)
    error_message = "유효하지 않은 환경입니다. 'prod' 또는 'test' 중 하나를 선택하세요."
  }
}
