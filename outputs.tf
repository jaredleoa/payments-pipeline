// outputs.tf

output "s3_bucket_name" {
  description = "S3 bucket for payments events"
  value       = aws_s3_bucket.payments_events.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table storing payment events"
  value       = aws_dynamodb_table.payments_events.name
}

output "lambda_function_name" {
  description = "Lambda function that writes mock payment events into DynamoDB"
  value       = aws_lambda_function.payments_writer.function_name
}

output "lambda_role_arn" {
  description = "IAM role ARN used by the Lambda function"
  value       = aws_iam_role.lambda_exec.arn
}
