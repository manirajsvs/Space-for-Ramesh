# # Create the ALB Ingress resource
# resource "kubernetes_ingress_v1" "nginx_ingress" {
#   metadata {
#     name      = "nginx-ingress"
#     namespace = "eventprocessor"
#     annotations = {
#       "kubernetes.io/ingress.class"                 = "nginx"
#       "nginx.ingress.kubernetes.io/affinity"        = "cookie"
#       "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
#       "nginx.ingress.kubernetes.io/ssl-redirect"    = "false"
#       "nginx.ingress.kubernetes.io/health-check-path" = "/"
#     }
#   }

#   spec {
#     rule {
#       http {
#         path {
#           path = "/"
#           backend {
#             service {
#               name = "nginx-svc"
#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }
#   }
#    depends_on = [null_resource.aws_ingress_controller]
# }

# # data "aws_caller_identity" "current" {}

# data "aws_region" "current" {}

# locals {
#   name = "portal-eks-dev"
# }

# resource "aws_alb" "alb" {
#   name               = "${local.name}-lb"
#   internal           = true
#   load_balancer_type = "application"
#   drop_invalid_header_fields = true
#   subnets            = var.subnets

#   security_groups = [
#     aws_security_group.alb-ingress.id,
#     aws_security_group.egress_all.id
#   ]
# }

# resource "aws_alb_listener" "http" {
#   load_balancer_arn = aws_alb.alb.arn
#   port              = var.port
#   protocol          = "HTTPS"
#   certificate_arn   = var.certificate_arn

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "It works"
#       status_code  = "200"
#     }
#   }
# }

# resource "aws_security_group" "egress_all" {
#   name        = "${local.name}-egress-all"
#   description = "Allow all outbound traffic"
#   vpc_id      = var.vpc_id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "alb-ingress" {
#   name        = "${local.name}-alb-ingress"
#   description = "Allow ingress to ALB"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = var.port
#     to_port     = var.port
#     protocol    = "TCP"
#     cidr_blocks = ["10.0.0.0/8"]
#   }
# }

# resource "null_resource" "aws_ingress_controller" {
#   provisioner "local-exec" {
#     command = <<EOF
#     helm repo add eks https://aws.github.io/eks-charts
#     kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
#     helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=portal-platform-eks-dev-cluster --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller --set region=us-east-1 --set vpcId=vpc-036c307b9de2b3a0f
    
#     EOF
#   }
#   #depends_on = [helm_release.argocd]
    
# }