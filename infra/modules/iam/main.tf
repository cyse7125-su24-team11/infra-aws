# All other roles & policies required for EKS cluster, node pool, and Amazon EBS CSI driver
# add-on should be created by Terraform.


## EKS ---- Cluster Service Role ---- ##
##
##

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name                  = var.eks_cluster_role
  assume_role_policy    = data.aws_iam_policy_document.eks_assume_role_policy.json
  force_detach_policies = true

  tags = {
    tag-key = var.eks_cluster_role
  }

  depends_on = [data.aws_iam_policy_document.eks_assume_role_policy]
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
  depends_on = [aws_iam_role.eks_cluster_role]
}

# resource "aws_iam_role_policy_attachment" "eks_AmazonEKSVPCResourceController" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
#   role       = aws_iam_role.eks_cluster_role.name
#   depends_on = [aws_iam_role.eks_cluster_role]
# }

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_role.name
  depends_on = [aws_iam_role.eks_cluster_role]
}

# resource "aws_iam_role_policy_attachment" "eks_AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_cluster_role.name
#   depends_on = [ aws_iam_role.eks_cluster_role ]
# }

resource "aws_iam_role_policy_attachment" "eks_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_role.name
  depends_on = [aws_iam_role.eks_cluster_role]
}

## EKS Add On ---- VPC CNI Role ---- ##
##
##

data "aws_iam_policy_document" "vpc_cni_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

# Creates and is configured to use a Kubernetes service account named aws-node 
# https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html
resource "aws_iam_role" "vpc_cni_role" {
  name                  = var.vpc_cni_role
  assume_role_policy    = data.aws_iam_policy_document.vpc_cni_assume_role_policy.json
  force_detach_policies = true

  tags = {
    tag-key = var.vpc_cni_role
  }
  depends_on = [aws_iam_openid_connect_provider.oidc_provider,
  data.aws_iam_policy_document.vpc_cni_assume_role_policy]
}

resource "aws_iam_role_policy_attachment" "vpc_cni_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_role.name
  depends_on = [aws_iam_role.vpc_cni_role]
}



## EKS Add On ---- Pod Identity Role ---- ##
##
##

data "aws_iam_policy_document" "pod_identity_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_pod_identity_role" {
  name                  = var.eks_pod_identity_role
  assume_role_policy    = data.aws_iam_policy_document.pod_identity_assume_role_policy.json
  force_detach_policies = true

  tags = {
    tag-key = var.eks_pod_identity_role
  }
  depends_on = [data.aws_iam_policy_document.pod_identity_assume_role_policy]
}



## EKS Add On  ---- EBS CSI Role ---- ##
##
##

data "aws_iam_policy_document" "ebs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_policy" "ebs_csi_kms_policy" {
  name = var.ebs_csi_kms_policy

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : [var.ebs_kms_key_arn],
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : [var.ebs_kms_key_arn]
      }
    ]
  })
}

resource "aws_iam_policy" "ebs_csi_custom_policy" {
  name = var.ebs_csi_custom_policy

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSnapshot"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/CSIVolumeSnapshotName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSnapshot"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role" "ebs_csi_role" {
  name                  = var.ebs_csi_role
  assume_role_policy    = data.aws_iam_policy_document.ebs_csi_assume_role_policy.json
  force_detach_policies = true

  tags = {
    tag-key = var.ebs_csi_role
  }
  depends_on = [data.aws_iam_policy_document.ebs_csi_assume_role_policy]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
  depends_on = [aws_iam_role.ebs_csi_role]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_kms_policy" {
  policy_arn = aws_iam_policy.ebs_csi_kms_policy.arn
  role       = aws_iam_role.ebs_csi_role.name
  depends_on = [aws_iam_role.ebs_csi_role]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_custom_policy" {
  policy_arn = aws_iam_policy.ebs_csi_custom_policy.arn
  role       = aws_iam_role.ebs_csi_role.name
  depends_on = [aws_iam_role.ebs_csi_role]
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node_group_role.name
  depends_on = [aws_iam_role.node_group_role]
}


## IAM role and policy for  ---- OIDC Identity Provider ---- ##
##
##

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list = ["sts.amazonaws.com"]
  # thumbprint_list = [var.oidc_cert.certificates[0].sha1_fingerprint]
  thumbprint_list = [var.oidc_cert]
  url             = var.oidc_provider_url
  depends_on      = []
}

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "oidc_iam_role" {
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  name               = "oidc_iam_role"
  depends_on         = [aws_iam_openid_connect_provider.oidc_provider]
}



## EKS  ---- Node Group Role ---- ##
##
##

data "aws_iam_policy_document" "node_group_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_group_role" {
  name                  = var.node_group_role
  assume_role_policy    = data.aws_iam_policy_document.node_group_assume_role_policy.json
  force_detach_policies = true

  tags = {
    tag-key = var.node_group_role
  }
  depends_on = [data.aws_iam_policy_document.node_group_assume_role_policy]

}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
  depends_on = [aws_iam_role.node_group_role]
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
  depends_on = [aws_iam_role.node_group_role]
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
  depends_on = [aws_iam_role.node_group_role]
}

resource "aws_iam_role_policy_attachment" "node_group_kms_policy" {
  policy_arn = aws_iam_policy.ebs_csi_kms_policy.arn
  role       = aws_iam_role.node_group_role.name
  depends_on = [aws_iam_role.node_group_role]
}

resource "aws_iam_policy" "pass_role_policy" {
  name = "pass_role_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pass_role_policy" {
  policy_arn = aws_iam_policy.pass_role_policy.arn
  role       = aws_iam_role.eks_pod_identity_role.name
  depends_on = [aws_iam_role.eks_pod_identity_role]
}



data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "ebs-pod-identity-role" {
  name               = "eks-pod-identity"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs-pod-identity-policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs-pod-identity-role.name
}

resource "aws_iam_role_policy_attachment" "ebs-pod-identity-custom-policy" {
  policy_arn = aws_iam_policy.ebs_csi_custom_policy.arn
  role       = aws_iam_role.ebs-pod-identity-role.name
  depends_on = [aws_iam_role.ebs-pod-identity-role, aws_iam_policy.ebs_csi_custom_policy]
}


## EKS ---- AutoScaler Service Role ---- ##
##
##

data "aws_iam_policy_document" "ca_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "ca_custom_policy" {
  name = var.ca_custom_policy

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": ["*"]
    }
  ]
})
}

resource "aws_iam_role" "ca-role" {
  name               = "eks-ca"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ca-policy" {
  policy_arn = aws_iam_policy.ca_custom_policy.arn
  role       = aws_iam_role.ca-role.name
}