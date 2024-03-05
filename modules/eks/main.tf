# EKS Cluster role
resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-cluster-role"
  tags = merge(var.default_tags, tomap({ "Name" = "eks-cluster-role" }))
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "eks.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }   
  )
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}
resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

# EKS Node Group role

resource "aws_iam_role" "eks-cluster-ng-role" {
  name = "eks-cluster-ng-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }],
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-cluster-ng-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-cluster-ng-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-cluster-ng-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-ng-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-cluster-ng-role.name
}

# Security Group for EKS cluster

resource "aws_security_group" "eks-cluster-sg" {
  name        = "eks-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id
  tags        = merge(var.default_tags, tomap({ "Name" = "eks-cluster-sg" }))

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  // Ingress rule allowing traffic from the VPC CIDR
  ingress {
    from_port   = 0    # Adjust the source port if needed
    to_port     = 0    # Adjust the destination port if needed
    protocol    = "-1" # Allow all protocols
    cidr_blocks = ["10.0.0.0/16"]
  }
  
}


# Security Group for EKS nodes

resource "aws_security_group" "eks-ng-sg" {
  name        = "eks-ng-sg"
  description = "Internal VPC - Nodes communication"
  vpc_id      = var.vpc_id
  tags        = merge(var.default_tags, tomap({ "Name" = "eks-ng-sg" }))

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Ingress rule allowing traffic from the VPC CIDR
  ingress {
    from_port   = 0    # Adjust the source port if needed
    to_port     = 0    # Adjust the destination port if needed
    protocol    = "-1" # Allow all protocols
    cidr_blocks = ["10.0.0.0/16"]
  }
}



# EKS Cluster

resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-cluster-role.arn
  tags     = merge(var.default_tags, tomap({ "Name" = "eks-cluster" }))
  
  
  vpc_config {
    security_group_ids      = [aws_security_group.eks-cluster-sg.id]
    subnet_ids              = var.eks_subnets_id
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
  ]

}


# Launch Template for EKS node group

resource "aws_launch_template" "eks-cluster_ng_launch_template" {

  name = "EKS_launch_template"

  vpc_security_group_ids = [
    aws_security_group.eks-ng-sg.id
  ]


  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size         = 30
      volume_type         = "gp3"
      iops                = 3000
      throughput          = 300
    }
  }

  image_id      = "ami-022df2ba836fa2917"
  instance_type = "t3.medium"

  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
/etc/eks/bootstrap.sh lab-eks-cluster

--==MYBOUNDARY==--\
  EOF
  )


  tag_specifications {
    resource_type = "instance"

    tags = merge(var.default_tags, tomap({ "Name" = "EKS_Managed_Node" }))
  }
  
}

# EKS Node Group

resource "aws_eks_node_group" "eks-cluster-ng" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "EKS_NG_0"
  node_role_arn   = aws_iam_role.eks-cluster-ng-role.arn
  subnet_ids      = var.eks_subnets_id

  tags = merge(var.default_tags, tomap({ "Name" = "EKS_ASG_Group" }))
  scaling_config {
    desired_size = var.asg_desired_size
    max_size     = var.asg_max_size
    min_size     = var.asg_min_size
  }

  launch_template {
   name = aws_launch_template.eks-cluster_ng_launch_template.name
   version = aws_launch_template.eks-cluster_ng_launch_template.latest_version
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-ng-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-cluster-ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-cluster-ng-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    create_before_destroy = true
  }
}


#############
# Addon EKS #
#############
# Data block to fetch EKS cluster information

 
data "aws_eks_cluster" "eks_cluster_info" {
  name = aws_eks_cluster.eks-cluster.name
}


module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version


  cluster_name      = aws_eks_cluster.eks-cluster.name
  
  cluster_endpoint  = data.aws_eks_cluster.eks_cluster_info.endpoint
  cluster_version   = data.aws_eks_cluster.eks_cluster_info.version
  oidc_provider_arn = data.aws_eks_cluster.eks_cluster_info.identity[0].oidc[0].issuer
  

  eks_addons = {
  /*
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  
  */
  
    // do this first
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }
  
  // enable_aws_load_balancer_controller = true

}

