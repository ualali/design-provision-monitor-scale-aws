terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }

  backend "local" {
    path = ".tfstate/terraform.tfstate"
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region

  default_tags {
    tags = {
      "Project"     = "nd063"
      "Environment" = "udacity"
    }
  }
}

data "archive_file" "lambda_file" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "lambda.zip"
}

resource "aws_iam_role" "lambda_role" {
  name               = "udacity_lambda_role"
  assume_role_policy = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
    EOT
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "udacity_lambda"

  role     = aws_iam_role.lambda_role.arn
  filename = "lambda.zip"
  handler  = "lambda.lambda_handler"
  runtime  = "python3.8"

  environment {
    variables = {
      greeting = "Hi there!"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

# resource "aws_cloudwatch_log_group" "lambda_logs" {
#   name              = "/aws/lambda/lambda_function_name_udacity"
#   retention_in_days = 14
# }
