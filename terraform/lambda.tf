data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flca_lambda" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Package the Lambda function code
data "archive_file" "example" {
  type        = "zip"
  source_dir = "${path.module}/../python/dist"
  output_path = "${path.module}/lambda/function.zip"
}

pip install \
    --platform manylinux2014_x86_64 \
    --target ./package \
    --only-binary=:all: \
    pynacl

# Lambda function
resource "aws_lambda_function" "example" {
  filename      = data.archive_file.example.output_path
  function_name = "flca_discord"
  role          = aws_iam_role.flca_lambda.arn
  handler       = "lambda_handler"
  code_sha256   = data.archive_file.example.output_base64sha256

  runtime = "python3.14"

  vpc_config {
    subnet_ids                  = [aws_subnet.public.id]
  }

  environment {
    variables = {
      NOCODB_TOKEN = var.nocodb_token
      NOCODB_DOMAIN = var.nocodb_domain
      SHIPS_TABLE_ID = var.ships_table_id
      DISCORD_BOT_PUBLIC_KEY = var.discord_bot_public_key
    }
  }

  tags = {
    Environment = "production"
    Application = "flca"
  }
}

