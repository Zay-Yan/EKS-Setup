# Call the networking module
module "vpc" {

  source = "./modules/vpc"
  az-a   = "us-west-2a"
  az-b   = "us-west-2b"
  az-c   = "us-west-2c"

}

# Call the EKS cluster module
module "eks" {

  source = "./modules/eks"
  
  vpc_id = module.vpc.vpc_id
  
  eks_subnets_id = module.vpc.eks_subnets_id
  
  asg_desired_size = 3
  asg_min_size = 3
  asg_max_size = 3
  
  
  default_tags = var.default_tags
}


# Call the alb module

module "alb" {
  source = "./modules/alb"
  
  vpc-igw = module.vpc.vpc-igw
  vpc_id = module.vpc.vpc_id
  alb_subnets = module.vpc.alb_subnets_id
  
}