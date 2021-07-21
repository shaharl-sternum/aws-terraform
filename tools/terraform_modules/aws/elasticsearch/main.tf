module "elasticsearch_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "~> 3.0"

  name                = "elasticsearch-sg"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.subnet_cidrs

  tags = var.tags
}

resource "aws_kms_key" "key" {
  description             = "ElasticSearch storage encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_iam_service_linked_role" "es-dev" {
  count            = var.create_es_linked_role ? 1 : 0
  aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.domain
  elasticsearch_version = var.elasticsearch_version

  node_to_node_encryption {
    enabled = var.node_to_node_encryption
  }

  encrypt_at_rest {
    enabled    = var.encrypt_at_rest
    kms_key_id = aws_kms_key.key.arn
  }

  advanced_security_options {
    enabled = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name = "admin"
      master_user_password = "null"
    }
  }

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.elasticsearch_node_count
    zone_awareness_enabled = length(var.azs) > 1
    zone_awareness_config {
      availability_zone_count = 2
    }

    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_type    = var.dedicated_master_type
    dedicated_master_count   = var.dedicated_master_count
  }

  vpc_options {
    subnet_ids = slice(var.subnet_ids, 0, 2)

    security_group_ids = [module.elasticsearch_security_group.this_security_group_id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = var.tags

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.volume_size
  }
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = aws_elasticsearch_domain.es.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": { "AWS": "*" },
            "Effect": "Allow",
            "Resource": "${aws_elasticsearch_domain.es.arn}/*"
        }
    ]
}
POLICIES
}