## S3 Bucket for applications with CodeDeploy enabled only

resource "aws_s3_bucket" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = "codedeploy-${local.container_name}-appspec"

  tags = module.this.tags
}

resource "aws_s3_object" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket  = aws_s3_bucket.appspec_artifacts[0].id
  key     = "${local.container_name}-appspec"
  content = local.appspec_sha256
  # Using etag for versioning, it will change if content changes
  etag = local.appspec_sha256

  tags = module.this.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = aws_s3_bucket.appspec_artifacts[0].id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }
  }
}