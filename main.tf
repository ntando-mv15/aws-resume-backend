
# Configure the AWS Provider
provider "aws" {
  region = var.myregion
}

#Dynamo DB Table

resource "aws_dynamodb_table" "visitor-counter" {
  name           = "visitor-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  # Define attributes for the DynamoDB table
  attribute {
    name = "id"
    type = "S"
  }
}

# Item for DynamoDB Table
resource "aws_dynamodb_table_item" "user_item" {
  table_name = aws_dynamodb_table.visitor-counter.name
  hash_key   = "id"
 item       = jsonencode({
    id    = {S = "1"}
    views = {N = "40"}
  })
}


#Lambda

# Archive file
data "archive_file" "zip-python" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/lambda_function"
  output_path = "${path.module}/output.zip"
}

# Lambda Function for Handling Web Page Visits
resource "aws_lambda_function" "myfunc" {
  filename      = "${data.archive_file.zip-python.output_path}"  
  function_name = "myfunc"
  role          = aws_iam_role.lambda_role.arn
  handler       = "counter-function.counter_handler" 
  runtime       = "python3.11"


  # Specify the source code for the Lambda function
  source_code_hash = data.archive_file.zip-python.output_base64sha256
}



# IAM Role for Lambda Function 
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Resume Project
resource "aws_iam_policy" "policy_for_resume_project" {
  name = "aws_iam_policy_for_resume_project"
  path = "/"
  description = "aws_iam_policy_for_resume_project"
    policy = jsonencode(
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Effect": "Allow",
                    "Resource": "arn:aws:logs:*:*:*"
                },
                {
                    "Action": [
                        "dynamodb:*"
                    ],
                    "Effect": "Allow",
                    "Resource": "arn:aws:dynamodb:*:*:table/visitor-counter"
                }
            ]
        }
    )
}


# Attach IAM Policy to Lambda role
resource "aws_iam_role_policy_attachment" "policy_to_lambda_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.policy_for_resume_project.arn
}

resource "aws_lambda_function_url" "url1" {
    function_name = aws_lambda_function.myfunc.function_name
    authorization_type = "NONE"

    cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}