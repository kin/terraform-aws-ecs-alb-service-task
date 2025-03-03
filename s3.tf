## S3 Bucket for applications with CodeDeploy enabled only

# resource "local_file" "appspec" {
#   count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0
#
#   content  = local.appspec_content
#   filename = "${path.module}/appspec.yml"
# }
#
# data "archive_file" "appspec" {
#   count       = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0
#   type        = "zip"
#   source_file = local_file.appspec[0].filename
#   output_path = "${path.module}/${local.container_name}-appspec.zip"
#   depends_on  = [local_file.appspec]
# }

resource "aws_s3_bucket" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = "${module.this.stage}-codedeploy-${local.container_name}-appspec"

  tags = module.this.tags
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = aws_s3_bucket.appspec_artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket     = aws_s3_bucket.appspec_artifacts[0].id
  key        = "${local.container_name}-appspec.yml"
  content    = local.appspec_content
  etag       = local.appspec_sha256 # Using etag for versioning, it will change if content changes
  tags       = module.this.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = aws_s3_bucket.appspec_artifacts[0].id

  rule {
    id     = "manage-old-versions"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 60
    }
  }
}