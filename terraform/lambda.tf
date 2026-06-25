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

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.flca_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.flca_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_role" {
  role       = aws_iam_role.flca_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_iam_role" "flca_lambda" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "function_payload" {
  type = "zip"
  source_file = "${path.root}/../python/discord.py"
  output_path = "${path.root}/lambda/function.zip"
}

data "archive_file" "layer_payload" {
  type        = "zip"
  source_dir = "${path.root}/../python/dist"
  output_path = "${path.root}/lambda/layer.zip"
}

resource "aws_lambda_layer_version" "flca" {
  filename   = data.archive_file.layer_payload.output_path
  layer_name = "discord_layer"

  source_code_hash = data.archive_file.layer_payload.output_base64sha256

  compatible_runtimes = ["python3.14"]
}

resource "aws_security_group" "allow_https" {

  name = "allow_https"
  description = "allow https from everywhere"
  vpc_id = aws_vpc.flca.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_https.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.allow_https.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_https.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_https.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_lambda_function" "flca" {
  filename      = data.archive_file.function_payload.output_path
  function_name = "flca_discord"
  role          = aws_iam_role.flca_lambda.arn
  handler       = "discord.lambda_handler"
  code_sha256   = data.archive_file.function_payload.output_base64sha256

  layers = [aws_lambda_layer_version.flca.arn]
  
  runtime = "python3.14"

  vpc_config {
    subnet_ids                  = [aws_subnet.public.id]
    security_group_ids = [aws_security_group.allow_https.id]
    ipv6_allowed_for_dual_stack = true
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

resource "aws_lambda_function_url" "flca" {
  function_name      = aws_lambda_function.flca.function_name
  authorization_type = "NONE"
}

output "lambda_url" {
  description = "lambda url"
  value = aws_lambda_function_url.flca.function_url
}
