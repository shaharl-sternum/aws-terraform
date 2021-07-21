module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  subnets         = var.private_subnet_ids
  tags            = var.tags
  cluster_version = var.cluster_version

  vpc_id = var.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = var.worker_group_1.instance_type
      asg_min_size         = var.worker_group_1.min_count
      asg_max_size         = var.worker_group_1.max_count
      asg_desired_capacity = var.worker_group_1.desired_count
      root_volume_size     = var.worker_group_1.root_size
      kubelet_extra_args   = var.worker_group_1.taint != "" ? "--node-labels=${var.worker_group_1.taint} --register-with-taints=${var.worker_group_1.taint}:NoSchedule" : ""
      tags = [{
          "key"                 = "k8s.io/cluster-autoscaler/enabled",
          "value"               = "true",
          "propagate_at_launch" = false
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${var.cluster_name}",
          "value"               = var.cluster_name
          "propagate_at_launch" = false
      }]
    }
  ]

  map_roles = [{
    "rolearn" : aws_iam_role.alex_eks_admin.arn,
    "username" : "admin",
    "groups" : ["system:masters"]
  },{
    "rolearn" : "arn:aws:iam::069425080139:role/alex-dev-eks-admin",
    "username" : "admin",
    "groups" : ["system:masters"]
  }]
  map_users                            = var.map_users
  worker_additional_security_group_ids = [aws_security_group.allow_all_from_public_subnets.id]
  workers_additional_policies          = ["arn:aws:iam::aws:policy/AmazonSQSFullAccess", aws_iam_policy.allow_external_dns_updates.arn]
}

resource "aws_iam_role" "alex_eks_admin" {
  name = "${var.env}-eks-admin"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::069425080139:root"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "assume_eks_admin_policy" {
  name        = "AssumeEKSAdminPolicy-dev-${var.env}"
  path        = "/"
  description = "Allow users to assume EKS admin role on ${var.env}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "${aws_iam_role.alex_eks_admin.arn}"
  }
}
EOF
}

resource "aws_iam_policy" "allow_external_dns_updates" {
  name        = "AllowExternalDNSUpdates-dev-${var.env}"
  path        = "/"
  description = "Allow external-dns to update DNS records"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
  EOF
}

resource "aws_iam_group_policy_attachment" "attach_policy_to_iam_group" {
  count      = var.iam_group_allow_access != null ? 1 : 0
  group      = var.iam_group_allow_access
  policy_arn = aws_iam_policy.assume_eks_admin_policy.arn
}

resource "aws_iam_user_policy_attachment" "attach_policy_to_iam_user" {
  count      = var.iam_user_allow_access != null ? 1 : 0
  user       = var.iam_user_allow_access
  policy_arn = aws_iam_policy.assume_eks_admin_policy.arn
}


resource "aws_security_group" "allow_all_from_public_subnets" {
  name        = "allow_all_from_public_subnets"
  description = "Allow all traffic from public subnets"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic from public subnets (for LB)"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = var.public_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "random_password" "secret_key" {
  length           = 16
  special          = true
  override_special = "_=*#"
}

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "admin_role_arn" {
  description = "ARN of the newly created admin role"
  value       = aws_iam_role.alex_eks_admin.arn
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = module.eks.worker_iam_role_name
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${module.eks.cluster_id}"
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
  path        = "/"
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name      = "cluster-autoscaler"
  chart     = "stable/cluster-autoscaler"
  namespace = "kube-system"

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "rbac.create"
    value = true
  }
}

# resource "kubernetes_namespace" "nginx_ingress" {
#   metadata {
#     annotations = {
#       name = "nginx-ingress"
#     }

#     name = "nginx-ingress"
#   }
# }

# resource "helm_release" "nginx_ingress" {
#   name      = "nginx-ingress"
#   chart     = "nginx-ingress"
#   namespace = kubernetes_namespace.nginx_ingress.metadata[0].name

#   set {
#     name  = "rbac.create"
#     value = true
#   }

#   set {
#     name  = "controller.service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "controller.service.externalTrafficPolicy"
#     value = "Local"
#   }

#   set {
#     name  = "controller.publishService.enabled"
#     value = true
#   }

#   set_string {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-proxy-protocol"
#     value = "*"
#   }

#   set_string {
#     name  = "controller.config.use-proxy-protocol"
#     value = "true"
#   }
# }

# resource "kubernetes_namespace" "cert_manager" {
#   metadata {
#     annotations = {
#       name = "cert-manager"
#     }

#     name = "cert-manager"
#   }
# }

# resource "helm_release" "cert_manager" {
#   name      = "cert-manager"
#   chart     = "../../../charts/cert-manager"
#   namespace = kubernetes_namespace.cert_manager.metadata[0].name
# }

# resource "kubernetes_namespace" "external_dns" {
#   metadata {
#     annotations = {
#       name = "external-dns"
#     }

#     name = "external-dns"
#   }
# }

# resource "helm_release" "external_dns" {
#   name      = "external-dns"
#   chart     = "../../../charts/external-dns"
#   namespace = kubernetes_namespace.cert_manager.metadata[0].name
# }
