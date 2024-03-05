variable "vpc-igw" {
}

variable "vpc_id" {
}

variable "alb_subnets" {
  type    = list(string)
  description = "List of subnet IDs for the ALB"
  # Add any default or validation constraints if needed
  default = []
}