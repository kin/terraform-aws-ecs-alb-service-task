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
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.appspec_artifacts[0].arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "codedeploy:*"
        Resource = "*"
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
        PollforSourceChanges = false
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

