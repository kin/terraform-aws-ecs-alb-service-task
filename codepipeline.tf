data "aws_caller_identity" "current" {}

// IAM
resource "aws_iam_role" "default" {
  name = "CodePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "codepipeline.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "default" {
  role = aws_iam_role.default.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.appspec_artifacts[0].arn,
          "${aws_s3_bucket.appspec_artifacts[0].arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "codedeploy:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "codepipeline:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.container_name}"
        ]
      }
    ]
  })
}

// CodePipeline
resource "aws_codepipeline" "default" {
  name     = local.container_name
  role_arn = aws_iam_role.default.arn

  artifact_store {
    location = aws_s3_bucket.appspec_artifacts[0].bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "S3Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        S3Bucket    = aws_s3_bucket.appspec_artifacts[0].bucket
        S3ObjectKey = "${local.container_name}-appspec"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "CodeDeploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ApplicationName     = local.container_name
        DeploymentGroupName = local.container_name
      }
    }
  }
}

