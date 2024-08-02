resource "aws_eks_node_group" "node_group" {
  version         = var.k8s_version
  cluster_name    = var.eks_cluster_name
  node_group_name = "${var.eks_cluster_name}-node-group"

  node_role_arn = var.node_group_iam_role.arn
  count         = length(var.public_subnets)
  subnet_ids = [
    var.public_subnets[0].id,
    var.public_subnets[1].id,
    var.public_subnets[2].id,
    var.private_subnets[0].id,
    var.private_subnets[1].id,
    var.private_subnets[2].id
  ]

  ami_type             = var.ami_type
  capacity_type        = var.capacity_type
  disk_size            = var.disk_size
  force_update_version = var.force_update_version
  instance_types       = var.instance_types # c3.large

  labels = {
    role = "${var.eks_cluster_name}-node-group-role",
    name = "${var.eks_cluster_name}-node-group"
  }

  # Configuration block - should be dynamic values
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  tags = {
    "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned",
    "k8s.io/cluster-autoscaler/enabled"                 = true
  }
  depends_on = [
    var.eks_cluster,
    var.oidc_provider,
    var.node_group_AmazonEKS_CNI_IAM,
    var.node_group_AmazonEKSWorkerNodeIAM,
  var.node_group_AmazonEC2ContainerRegistryReadOnlyIAM]
  # , var.ebs_csi
}




# resource "aws_launch_template" "eks_launch_template" {
#   name_prefix = "eks_launch_template"

#   # image_id                = "ami-01fccab91b456acc2" #ami_type mentioned in node_group
#   instance_type           = "c3.large"
#   key_name                = "ec2"
#   block_device_mappings {
#     device_name = "/dev/sdf"
#     ebs {
#       volume_size = var.disk_size
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   network_interfaces {
#       associate_public_ip_address = true
#       security_groups = [var.eks_sg.id]
#     }

#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned",
#       "k8s.io/cluster-autoscaler/enabled"                 = true
#     }
#   }
#   user_data = base64encode(<<-EOF
#               MIME-Version: 1.0
#               Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

#               --==MYBOUNDARY==
#               Content-Type: text/x-shellscript; charset="us-ascii"

#               #!/bin/bash
#               set -ex
#               /etc/eks/bootstrap.sh ${var.eks_cluster_name} \
#                 --kubelet-extra-args '--max-pods=20' \
#                 --use-max-pods false

#               --==MYBOUNDARY==--
#               EOF
#   ) 
# }

# resource "aws_eks_node_group" "node_group" {
#   version         = var.k8s_version
#   cluster_name    = var.eks_cluster_name
#   node_group_name = "${var.eks_cluster_name}-node-group"

#   node_role_arn = var.node_group_iam_role.arn
#   subnet_ids = [
#     var.public_subnets[0].id,
#     var.public_subnets[1].id,
#     var.public_subnets[2].id,
#     var.private_subnets[0].id,
#     var.private_subnets[1].id,
#     var.private_subnets[2].id
#   ]
#   launch_template {
#     id      = aws_launch_template.eks_launch_template.id
#     version = "$Latest"
#   }
#   ami_type             = var.ami_type
#   # ami_type = "CUSTOM"
#   force_update_version = var.force_update_version

#   labels = {
#     role = "${var.eks_cluster_name}-node-group-role",
#     name = "${var.eks_cluster_name}-node-group"
#   }

#   # Configuration block - should be dynamic values
#   scaling_config {
#     desired_size = var.desired_size
#     max_size     = var.max_size
#     min_size     = var.min_size
#   }

#   update_config {
#     max_unavailable = var.max_unavailable
#   }

#   tags = {
#     "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned",
#     "k8s.io/cluster-autoscaler/enabled"                 = true
#   }
#   depends_on = [
#     aws_launch_template.eks_launch_template,
#     var.eks_cluster, 
#     var.oidc_provider, 
#     var.node_group_AmazonEKS_CNI_IAM,
#     var.node_group_AmazonEKSWorkerNodeIAM, 
#     var.node_group_AmazonEC2ContainerRegistryReadOnlyIAM]
#   # , var.ebs_csi
# }

# resource "aws_autoscaling_group" "eks_asg" {

#   name = "eks-asg"
#   vpc_zone_identifier  = [
#     var.public_subnets[0].id,
#     var.public_subnets[1].id,
#     var.public_subnets[2].id,
#     var.private_subnets[0].id,
#     var.private_subnets[1].id,
#     var.private_subnets[2].id
#   ] 
#   min_size             = 3
#   max_size             = 6
#   desired_capacity     = 3
#   force_delete       = true


#   launch_template {
#     id      = aws_launch_template.eks_launch_template.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "name"
#     value               = "eks-asg"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "k8s.io/cluster-autoscaler/enabled"
#     value               = "true"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
#     value               = "true"
#     propagate_at_launch = true
#   } 
#   lifecycle {
#     create_before_destroy = true
#   }
#   depends_on = [ 
#     aws_launch_template.eks_launch_template, 
#     aws_eks_node_group.node_group 
#     ]
# }


# resource "aws_autoscaling_policy" "scale_up" {
#   name = "scale_up"
#   cooldown = 60
#   adjustment_type = "ChangeInCapacity"
#   scaling_adjustment = "1"
#   autoscaling_group_name = "${aws_autoscaling_group.eks_asg.name}"
#   depends_on = [ aws_autoscaling_group.eks_asg ]
# }

# resource "aws_autoscaling_policy" "scale_down" {
#   name = "scale_down"
#   cooldown = 60
#   adjustment_type = "ChangeInCapacity"
#   scaling_adjustment = "-1"
#   autoscaling_group_name = "${aws_autoscaling_group.eks_asg.name}"

#   depends_on = [ aws_autoscaling_group.eks_asg ]
# }