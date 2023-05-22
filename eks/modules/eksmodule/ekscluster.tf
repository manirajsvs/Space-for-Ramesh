
resource "aws_eks_cluster" "mycluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version                   = var.cluster_version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler" ]
  depends_on = [aws_security_group.create_sg]

  vpc_config {
    #cluster_security_group_id      = aws_security_group.create_sg.id
       #cluster_security_group_id            = var.cluster_security_group_id
       #security_group_ids      = var.cluster_security_group_id
       security_group_ids = var.cluster_security_group_id == null ? [data.aws_security_group.mysg.id] : var.cluster_security_group_id 
       #security_group_ids      = var.cluster_security_group_id == null ? data.aws_security_group.mysg.id : var.cluster_security_group_id
#subnet_ids = var.subnet_ids == null ? data.aws_subnets.private.ids : var.cluster_subnets   #The value is determined by a conditional expression that checks if the var.subnet_ids variable is null. If it is null, the value of subnets_ids is set to the list of IDs of private subnets retrieved using the data.aws_subnets.private.ids data source. Otherwise, the value of subnets_ids is set to the value of var.subnet_ids
    subnet_ids              = var.cluster_subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }


  kubernetes_network_config {

   # ip_family = "ipv4"
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = var.eks_tags

}

############  Nexus #################################
/*

# Provision an EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  #key_name      = "my-key-pair"
  vpc_security_group_ids = [aws_security_group.example.id]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    #private_key = file("~/.ssh/my-key-pair.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      # Install Java and other dependencies
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-8-jdk wget",

      # Download and install Nexus Artifactory
      "cd /tmp",
      "wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz",
      "tar -xvf latest-unix.tar.gz",
      "sudo mv nexus-* /opt/nexus",
      "sudo adduser nexus",
      "sudo chown -R nexus:nexus /opt/nexus",
      "sudo sed -i 's/#run_as_user/run_as_user/g' /opt/nexus/bin/nexus.vmoptions",
      "sudo ln -s /opt/nexus/bin/nexus /etc/init.d/nexus",
      "sudo update-rc.d nexus defaults",

      # Start Nexus Artifactory
      "sudo service nexus start"
    ]
  }
}

# Define a security group to allow SSH and HTTP traffic
resource "aws_security_group" "example" {
  name_prefix = "example-sg-"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

*/
#Set the KUBECONFIG environment variable
# locals {
#   kubeconfig = "~/.kube/config"  # Replace with the correct path to your kubeconfig file
# }
# Use the kubeconfig variable in provider
# provider "kubernetes" {
#   config_path = local.kubeconfig
# }

/*
resource "kubernetes_deployment" "tfnexus" {
  metadata {
    name = "terraformnexus"
    namespace = "default"
    labels = {
      app = "nexus"
    }
  }

  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "nexus"
      }
    }

    template {
      metadata {
        labels = {
          app = "nexus"
        }
      }

      spec {
        container {
          name = "nexus"
          image = "sonatype/nexus3:latest"
          port {
            container_port = 8081
          }
          volume_mount {
            name       = "nexus-data"
            mount_path = "/nexus-data"
          }
          env {
            name  = "NEXUS_SECURITY_RANDOMPASSWORD"
            value = "false"
          }
          env {
            name  = "NEXUS_CONTEXT"
            value = "/nexus"
          }
          env {
            name  = "NEXUS_SECURITY_REALM"
            value = "NexusAuthenticatingRealm"
          }
          env {
            name  = "NEXUS_SECURITY_PROVIDER"
            value = "FileAuthenticationProvider"
          }
        }

        volume {
          name = "nexus-data"
          empty_dir {}
        }
      }
    }
  }
  timeouts {
    create = "5m"
  }
}


# Expose the Nexus service to the internet
resource "kubernetes_service" "nexus" {
  metadata {
    name = "nexus"
    namespace = "default"
  }

  spec {
    selector = {
      app = "nexus"
    }

    port {
      name = "http"
      port = 8081
      target_port = 8081
    }

    type = "LoadBalancer"
  }
}
*/

resource "kubernetes_cluster_role" "cluster_role" {
  metadata {
    name = "eks-console-dashboard-full-access-clusterrole"
    annotations      = {}
    labels           = {}
  }
  rule {
    api_groups = [""]
    resources = [""]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
    non_resource_urls = []
    resource_names    = []
  }
  depends_on = [aws_eks_cluster.mycluster]
}
resource "kubernetes_cluster_role_binding" "cluster_role_binding" {
  metadata {
    name = "eks-console-dashboard-full-access-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_role.metadata[0].name
  }
  subject {
    kind      = "Group"
    name      = "eks-console-dashboard-full-access-group"
    api_group = "rbac.authorization.k8s.io"
  }
  depends_on = [aws_eks_cluster.mycluster]
}

resource "kubernetes_config_map" "aws_auth" {

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  depends_on = [aws_eks_cluster.mycluster]
    lifecycle {

    ignore_changes = [data]
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {  
  force = true                                         
  metadata {                                           
    name      = "aws-auth"                             
    namespace = "kube-system"                          
  }                                                    
                                                       
  data = {                                             
    mapRoles = yamlencode(var.map_roles)               
    mapUsers    = yamlencode(var.map_users)            
    mapAccounts = yamlencode(var.map_accounts)         
  }   
  depends_on = [aws_eks_cluster.mycluster, kubernetes_config_map.aws_auth]                                                 
}


resource "null_resource" "kubectl" {
triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOF
        aws eks --region us-east-1 update-kubeconfig --name ${aws_eks_cluster.mycluster.id}
        annotation_value=$(kubectl get deployment -n kube-system "coredns" -o jsonpath="{.spec.template.metadata}" | grep eks.amazonaws.com/compute-type)

        if [ -z "$annotation_value" ]; then
        echo "EC2 not set for deployment"
        else
        echo "Removing annotation from deployment"
        kubectl patch deployment coredns -n kube-system --type=json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'
        kubectl rollout restart -n kube-system deployment coredns
        while [[ $(kubectl get deployment -n kube-system coredns -o 'jsonpath={..status.conditions[?(@.type=="Available")].status}') != "True" ]]; do
        echo "Waiting for the deployment to be ready..."
        sleep 5
        done
        echo "Deployment is now ready"
        fi
    EOF
}
depends_on = [aws_eks_cluster.mycluster, aws_eks_fargate_profile.fargate-profile]
}

data "aws_security_group" "mysg" {
  id = aws_security_group.create_sg.id
}

output "cluster_status" {
  value = aws_eks_cluster.mycluster.status
}

