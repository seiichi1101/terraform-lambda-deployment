# Terraform Setting
terraform {
  required_version = "0.12.6"
}

# Provider
provider "aws" {
  region  = "ap-northeast-1"
  version = "~>2.34.0"
}

# Variables
variable "system_name" {
  default="terraform-lambda-deployment"
}

# Archive
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "build/layer"
  output_path = "lambda/layer.zip"
}
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "build/function"
  output_path = "lambda/function.zip"
}

# Layer
resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "${var.system_name}_lambda_layer"
  filename   = "${data.archive_file.layer_zip.output_path}"
  source_code_hash = "${data.archive_file.layer_zip.output_base64sha256}"
}

# Function
resource "aws_lambda_function" "get_unixtime" {
  function_name = "${var.system_name}_get_unixtime"

  handler                        = "src/get_unixtime.lambda_handler"
  filename                       = "${data.archive_file.function_zip.output_path}"
  runtime                        = "python3.6"
  role                           = "${aws_iam_role.lambda_iam_role.arn}"
  source_code_hash               = "${data.archive_file.function_zip.output_base64sha256}"
  layers = ["${aws_lambda_layer_version.lambda_layer.arn}"]
}

# Role
resource "aws_iam_role" "lambda_iam_role" {
  name = "${var.system_name}_iam_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

# Policy
resource "aws_iam_role_policy" "lambda_access_policy" {
  name   = "${var.system_name}_lambda_access_policy"
  role   = "${aws_iam_role.lambda_iam_role.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
POLICY
}
