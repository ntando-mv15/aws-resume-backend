
# Configure the AWS Provider
provider "aws" {
  region = var.myregion
}

#Dynamo DB Table

resource "aws_dynamodb_table" "visitor-counter" {
  name           = "visitor-counter"
  billing_mode = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  
  # Define attributes for the DynamoDB table
  attribute {
    name = "id"
    type = "S"
  }

    attribute {
    name = "id"
    type = "N"
  }

 # Assign tags to the table for easier management and identification
  tags = {
    Name        = "visitor-counter"
    Environment = "production"
  }
}


# API Gateway REST API

resource "aws_api_gateway_rest_api" "lambda-api" {
  name = "lambda-api"
}

# Define a resource for handling page visits
resource "aws_api_gateway_resource" "pageVisits" {
  path_part   = "webPageVisits"
  parent_id   = aws_api_gateway_rest_api.lambda-api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.lambda-api.id

}

# Define a method for handling GET requests
resource "aws_api_gateway_method" "GETVisits" {
  rest_api_id   = aws_api_gateway_rest_api.lambda-api.id
  resource_id   = aws_api_gateway_resource.pageVisits.id
  http_method   = "GET"
  authorization = "NONE"
}

# Define integration between API Gateway and Lambda function
resource "aws_api_gateway_integration" "lambda-integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda-api.id
  resource_id             = aws_api_gateway_resource.pageVisits.id
  http_method             = aws_api_gateway_method.GETVisits.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webPageVisits.invoke_arn
}

#Lambda

#archive file
# Archive file
data "archive_file" "zip-python" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/lambda_function"
  output_path = "${path.module}/output.zip"
}

# Lambda Function for Handling Web Page Visits
resource "aws_lambda_function" "webPageVisits" {
  filename      = "${data.archive_file.zip-python.output_path}"  
  function_name = "webPageVisits"
  role          = aws_iam_role.lambda-role.arn
  handler       = "counter-function.counter_handler" 
  runtime       = "python3.11"

  # Specify the source code for the Lambda function
  source_code_hash = data.archive_file.zip-python.output_base64sha256
}

# Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webPageVisits.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.lambda-api.id}/*/${aws_api_gateway_method.GETVisits.http_method}${aws_api_gateway_resource.pageVisits.path}"
}


# IAM Role for the Lambda Function
resource "aws_iam_role" "lambda-role" {
  name               = "lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# IAM Policy Document for Lambda Role
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

