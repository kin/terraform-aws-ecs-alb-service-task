## S3 Bucket for applications with CodeDeploy enabled only

resource "local_file" "appspec" {
  count    = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  content  = local.appspec_content
  filename = "${path.module}/appspec.yml"
}

resource "null_resource" "zip_appspec" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  triggers = {
    appspec_content_hash = local.appspec_sha256
  }

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.module}
      rm -f appspec.zip
      zip appspec.zip appspec.yml
      [ -f appspec.zip ] || (echo "Failed to create appspec.zip" && exit 1)
    EOT
  }

  depends_on = [local_file.appspec]
}

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
  count   = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket  = aws_s3_bucket.appspec_artifacts[0].id
  key     = "source/appspec.zip"
  source  = "${path.module}/appspec.zip"
  etag    = local.appspec_sha256
  tags    = module.this.tags

  depends_on = [null_resource.zip_appspec]
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