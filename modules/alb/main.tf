# Create security group for alb
resource "aws_security_group" "eks-alb-sg" {
  name        = "eks-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow http user traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow user traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow everything"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


# Create Application load balancer 
resource "aws_lb" "eks-alb" {

  name               = "lab-eks-lb"
  
  
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.eks-alb-sg.id]
  subnets            = var.alb_subnets
  enable_deletion_protection = false
  depends_on = [var.vpc-igw]
}

# Create target group

resource "aws_lb_target_group" "lab-alb-tg" {
  name        = "lab-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"  // instance 
  vpc_id      = var.vpc_id

  # my node app replies HTTP "200" on /health path
  health_check {
    interval            = 15
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3

    matcher = "200-499"  # Allow any HTTP status code in the range 200-499
    
  }
}


# Create listener for alb on port 80
resource "aws_lb_listener" "lab-alb-lsnr" {
  load_balancer_arn = aws_lb.eks-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab-alb-tg.arn
  }
}