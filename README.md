# Payments Event Pipeline (Terraform + AWS)

Infrastructure-as-Code for a minimal FinTech-aligned payments ingestion pipeline.  
Terraform provisions:

– S3 bucket  
– DynamoDB table  
– IAM execution role  
– Lambda function that generates mock payment events and writes them to DynamoDB  

Everything is deployable from a local workstation (VS Code + Terraform + AWS CLI).

---

## Architecture

1. Lambda generates a mock payment event with fields:
   - payment_id (UUID)
   - created_at (ISO8601)
   - amount (Decimal)
   - currency
   - merchant_id
   - status
   - source

2. Lambda writes events into a DynamoDB table:
   - PK: payment_id
   - SK: created_at

3. Terraform manages lifecycle of all components.

---

## Requirements

Local machine:

- Terraform ≥ 1.6  
- AWS CLI v2  
- Python 3.x  
- `zip` utility  
- AWS access key configured (`aws configure`)

---

## Folder Structure

payments-event-pipeline/
├── main.tf
├── variables.tf
├── outputs.tf
├── lambda/
│ └── handler.py
└── README.md

---

## Lambda Packaging

From project root:

cd lambda
rm -f lambda.zip
zip lambda.zip handler.py
cd ..

Terraform expects the file at `lambda/lambda.zip`.

---

## Deployment

Initialize providers:
terraform init

Validate:
terraform validate

Preview infrastructure:
terraform plan

Apply:
terraform apply


Approve.

---

## Outputs

After apply, Terraform prints:

- `s3_bucket_name`
- `dynamodb_table_name`
- `lambda_function_name`
- `lambda_role_arn`

Confirm via:
terraform output

---

## Invoke the Lambda

Extract the function name:
terraform output -raw lambda_function_name


Invoke with a payload requesting 3 mock payment events:
aws lambda invoke
--function-name <name>
--cli-binary-format raw-in-base64-out
--payload '{"count":3}'
response.json

Inspect:
cat response.json


---

## Validate DynamoDB Inserts

AWS Console → DynamoDB → Tables → `<project>-<env>-payments` → Items.

You should see multiple rows written by Lambda.

---

## Destroy All Resources

terraform destroy


Approve. This removes:

– S3 bucket  
– DynamoDB table  
– Lambda  
– IAM role + policy  
– CloudWatch log group  

---

