# Infra as Code - Assignment Instructions for IaC Course

## Overview

This is a template repo for participants to use to create their assignment solution for the IaC course.  It requires the following steps:

1. Create a new private repo based on a clone of this repo
2. Refactor and implement terraform code in line with the requirements below
3. Deploy the solution successfully using Github Actions
4. Update README.md to provide guidance based on your implementation

![Assignment details and diagram](./images/assignment.png)

So in this IaC course you have been working with AWS VPCs, EC2s, ECS, S3, RDS and DynamoDB but the focus has been to learn Terraform as well as gain some experience with AWS.  As you can see from the diagram above, in this assignment we're going to create a new solution with different AWS services to give you exposure to a serverless architecture.


## What is API Gateway and Lambda?

If you have not come across these services before then we recommend watching one or more of these videos.  The last two videos are more specific in how these services interact with each other which directly relates to this assignment.  Obviously these videos use the AWS Console whereas we will be implementing our solution using Terraform.

- [What is Amazon API Gateway?](https://www.youtube.com/watch?v=1XcpQHfTOvs)
- [AWS Lambda In Under FIVE Minutes](https://www.youtube.com/watch?v=LqLdeBj7CN4)
- [Create a REST API with API Gateway and Lambda](https://www.youtube.com/watch?v=jgpRAiar2LQ)
- [Use Amazon API Gateway with AWS Lambda](https://www.youtube.com/watch?v=aH6S_UKxJ-M)


## Components

### API Gateway
- It serves as the first point-of-contact for the end-user, and it helps to redirect requests from the user based on the URL.
  - Requests to “/register” are forwarded to the Lambda which handles user registration
  - Requests to “/” are forwarded to the the Lambda which handles user verification
- The simplest option to deploy it using [HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html) from AWS, which is a RESTful application
- Once the API-Gateway is set up, deploy [routes](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-routes.html) for each of the two paths, i.e., “/” and “/register”. For each route:
  - Add the [integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) resource to connect the Lambda with it. Use  “AWS_PROXY” as integration-type
  - Add the correct Lambda permissions to allow API-gateway to invoke its connected Lambda function
- [Deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_deployment) this API-Gateway with [$default stage](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-stages.html)
- You will create multiple API integrations, API routes and Lambda permissions to invoke the API, you should avoid code duplication. 
- There are no extra DNS requirements in this solution as the API Gateway service provides a public URL which can be used to interact with the solution.


### Request-Processing Lambdas
- Each of the two Lambda functions receives a request and will process it based on the query-string parameters in the request.
- Ideally you should set up Lambdas using [for_each](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each) or some similar form of iterative logic, in order to avoid code duplication.
- The Lambda code is currently in the src directory.
- Ensure that if you make a change to just the Lambda code and rerun the Terraform workflow it will recognise and deploy the changes.


### DynamoDB
- A Database is needed here to save userId when registering user, and then later also used for verification of user when calling verify-user Lambda function
- Set up [DynamoDB](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) in the simplest way possible.
Use “PAY_PER_REQUEST” as the billing mode, to avoid billing of idle resources.
- Hint: your DynamoDB hash_key should match your query string key.


### S3 Bucket
- An S3 bucket serves as a static website, and contains the homepage and error page of your website.
- Try to deploy S3 bucket using the [S3 public module](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest) as it gives you an opportunity to experiment with public modules
- Upload the homepage (index.html) and error-page (error.html) using [S3 Object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) resource. Try using count or for_each to create both objects while avoiding code duplication.


## Implementation Instructions
1. Create a new private repo based on a clone of this repo.
2. Use the AWS Beach account #160071257600 (TW_CORE_BEACH_R_D) and an AWS region which is suitable in relation to your geographical location for your deployments.  For more information on how to access the AWS Beach account see [BEACH.md](./BEACH.md).
3. It's possible you could create resources with the same name as others in this AWS account, to avoid conflicts wherever possible please use unique names for your resources (e.g. include your initials or firstname/lastname as prefix or suffix).
4. Deploy all resources using Terraform, e.g. no deployments or changes via AWS console.
5. Try using Terraform modules as much as possible, in order to organize your code better.
6. Avoid code duplication, by using modules and iterations (for loops or count) whenever possible.
7. Ensure in your Terraform output you display the dynamoDB ARN, S3 bucket ARN and the API Gateway URL.
8. We strongly recommend adding CloudWatch log groups to your Lambda as it will really help when troubleshooting any testing of the application.
9. Set up remote state and your GitHub IAM role resources as an initial Terraform deployment using local state.  The GitHub IAM role uses OIDC and should be restricted to your repository and apply least privilege principle with regards to the IAM role permissions neceesary for the GitHub Actions to deploy your solution.  You should understand how IAM Roles and OIDC works with GitHub based on the techniques learned in the last course session.
10. Setup a github actions workflow to deploy your terraform code which uses the remote state.  A boilerplate github workflow is available in the .github/workflows directory.
Configure the GitHub Action to create the cloud resources as well destroying them (you could use the same workflow file or separate ones, extra points for being DRY in your GitHub Actions).  All Terraform related workflows that interact with AWS should assume the same GitHub IAM role created in step 8 above.
12. Add [extra automated build steps](https://docs.google.com/presentation/d/1468DXJZPzhKKLAlxz6z7zhvYlkNLOaSCHztUYbQNKAI/edit#slide=id.g2c02383fe93_0_0) in the GitHub Actions deployment for the following (include examples of one of the three optionals):
  - formatting (mandatory)
  - linting (mandatory)
  - security (optional)
  - testing (optional)
  - documentation (optional)
12. Update your repositories README making an assumption that it's the first time the person has come across your code therefore you should explain and guide them through how to use it.  Feel free to expand on some of the key decisions you've made in your design.


## Least Privilege Principle

Both Lambda functions require an IAM role to be associated with them which have permissions to interact with other AWS services like DynamoDB.  As an infra engineer we should always operate with a security best practice mindset and adhere to the least privilege principle.  For example, we can allocate permissions like the policy statement below however that would be too open (the wildcard * allows everything).  You should be able to restrict what actions are allowed and restrict what resources the actions can be applied to. 

```
        {
            "Effect": "Allow",
            "Action": "dynamodb:*",
            "Resource": "*"
        }
```


## How to Submit your Assignment
Contact your trainers and ask for their GitHub usernames so you can explicitely grant permission for them to access your repo.


## Shared Responsibility
- Please remember to destroy your resources after testing your deployment. This will help us keep the costs under control so we can continue to offer these hands on training courses in the future. 
- Use the shared account responsibly.  Do not create users/static credentials, always use the okta aws access chicklet to get temporary credentials if required and do not store credentials insecurely


## Clean Up Instructions
1. Run your Terraform GitHub Action and ensure it completes successfully to destroy all of your infrastructure.  Do double check in the AWS Console (UI) that the resources have been deleted.
2. Run terraform destroy locally to destroy your remote state and GitHub IAM role.
