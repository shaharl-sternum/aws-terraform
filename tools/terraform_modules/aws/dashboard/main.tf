resource "aws_s3_bucket" "b" {
  bucket = var.bucket_name
  acl    = "public-read"
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
        "Sid":"PublicReadForGetBucketObjects",
        "Effect":"Allow",
          "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.bucket_name}/*"]
    }
  ]
}
EOF

  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "lambda-execution-role-${var.env}"
  description        = "Managed by Terraform"
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": {
            "Service": [
               "lambda.amazonaws.com",
               "edgelambda.amazonaws.com"
            ]
         },
         "Action": "sts:AssumeRole"
      }
   ]
}
EOF

  tags = var.tags
}

data "archive_file" "set_security_headers" {
  type        = "zip"
  source_file = "${path.module}/set_security_headers.js"
  output_path = "${path.module}/set_security_headers.js.zip"
}

resource "aws_lambda_function" "response_security_headers_v2" {
  description      = "Managed by Terraform, Set cloudfront response security headers"
  filename         = data.archive_file.set_security_headers.output_path
  function_name    = "set_security_headers_${var.env}"
  handler          = "set_security_headers.handler"
  source_code_hash = data.archive_file.set_security_headers.output_base64sha256
  publish          = true
  role             = aws_iam_role.lambda_execution.arn
  runtime          = "nodejs10.x"

  tags = var.tags
}


resource "aws_acm_certificate" "cert" {
  domain_name       = var.dns
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  name         = var.route53_zone
  private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options: dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.zone.id
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options: dvo.domain_name => {
      record = dvo.resource_record_value
    }
  }
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [each.value.record]
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id   = var.bucket_name
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${var.bucket_name}.s3.amazonaws.com"
    prefix          = "cloudfront_logs"
  }

  aliases = [var.dns]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.bucket_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.response_security_headers_v2.qualified_arn
      include_body = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }


  depends_on = [aws_acm_certificate.cert]
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.zone.id
  name    = var.dns
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.s3_distribution.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]
}