variable "default_tags" {
  type = map(any)
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "eks_subnets_id" {
  description = "EKS subnets ID"
}

variable "cluster_name" {
  default = "lab-eks-cluster"
  type    = string
}

variable "main-region"{
  default = "ap-southeast-1"
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}

variable "asg_desired_size" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
}


