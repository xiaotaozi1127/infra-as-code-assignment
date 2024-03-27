# Infra as Code - Assignment Instructions for IaC Course

## Overview

This is a template repo for participants use to create their assignment solution for the IaC course.  It requires the following steps:

1. Fork this repo to your become one of your private repositories
2. Refactor and implement terraform code in line with the requirements below
3. Deploy the solution successfully using Github Actions
4. Update README.md to provide guidance based on your implementation

![Assignment details and diagram](https://github.com/tw-infrastructure-academy/ia001-assignment-solution-template/blob/main/images/assignment.png)


## Components

### API Gateway:

- It serves as the first point-of-contact for the end-user, and it helps to redirect requests from the user based on the URL.
  - Requests to “/register” are forwarded to the Lambda which handles user registration
  - Requests to “/” are forwarded to the the Lambda which handles user verification
- The simplest option to deploy it using [HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html) from AWS, which is a RESTful application
- Once the API-Gateway is set up, deploy [routes](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-routes.html) for each of the two paths, i.e., “/” and “/register”. For each route:
  - Add the [integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) resource to connect the Lambda with it. Use  “AWS_PROXY” as integration-type
  - Add the correct Lambda permissions to allow API-gateway to invoke its connected Lambda function
- [Deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_deployment) this API-Gateway with [$default stage](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-stages.html)


### Request-Processing Lambdas:

- Each of the two Lambda functions receives a request and will process it based on the query-string parameters in the request.
- Ideally you should set up Lambdas using [for_each](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each) or some similar form of iterative logic, in order to avoid code duplication.
- The code is in the src directory.


### DynamoDB (or any DB of your choice):
- A Database is needed here to save userId when registering user, and then later also used for verification of user when calling verify-user Lambda function
- Set up [DynamoDB](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) in the simplest way possible
Use “PAY_PER_REQUEST” as the billing mode, to avoid billing of idle resources.
- In case you decide to use another Database, please try to use a Serverless database, as this can save costs of unused resources.


### S3 Bucket:
- S3 bucket serves as a static website, and contains the homepage and error-page of your website.
- Try to deploy S3 bucket using the [S3 public module](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest) as it gives you an opportunity to experiment with public modules
- Upload the homepage (index.html) and error-page (error.html) using [S3 Object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) resource. Try using count or for_each to create both objects while avoiding code duplication.


## Implementation Instructions:
1. Fork this repository to become your own private repo.
2. Use the shared AWS account #510769981514 (TW_TDEV_INFRACA:CORETEAM:DEV) and an AWS region which is suitable in relation to your geographical location for your deployments.
3. It's possible you could create resources with the same name as others in this AWS account, to avoid conflicts wherever possible please use unique names for your resources (e.g. include your initials, firstname/lastname as prefix or suffix).
4. Deploy all resources using Terraform, e.g. no deployments or changes via AWS console.
5. Try using Terraform modules as much as possible, in order to organize your code better.
6. Avoid code duplication, by using modules and iterations (for loops or count) whenever possible.
7. Set up remote state and your GitHub IAM role resources as an initial Terraform deployment using local state.  The GitHub IAM role uses OIDC and should be restricted to your repository and apply least privilege principle with regards to the IAM role permissions neceesary for the GitHub Actions.  You should be understand who IAM Roles and OIDC works with GitHub from using the techniques learned in the last session.
8. The rest of your code should be deployed in one go and utilises the remote state you created in the previous step. Resolve any dependency issues by using the depends_on block where needed.
9. Setup a github actions workflow to deploy your terraform code, a boilerplate github workflow is available in the .github/workflows directory.
Configure a GitHub Action to create the resources and another one for destroying them, they both should assume the same GitHub IAM role created in step 7 above.
10. Add [extra automated build steps](https://docs.google.com/presentation/d/1468DXJZPzhKKLAlxz6z7zhvYlkNLOaSCHztUYbQNKAI/edit#slide=id.g2c02383fe93_0_0) in the GitHub Actions deployment for the following (included examples of two of the three optionals):
  - formatting (mandatory)
  - linting (mandatory)
  - security (optional)
  - testing (optional)
  - documentation (optional)
11. Update the README making an assumption that the person reading it has never come across this repo before so it should explain and guide them through how to use it.


## Shared Responsibility:
- Please remember to destroy your resources after testing your deployment. This will help us keep the costs under control so we can continue to offer these hands on training courses in the future. 
- Use the shared account responsibly.  Do not create users/static credentials, always use the okta aws access chicklet to get temporary credentials if required and do not store credentials insecurely


## Clean Up Instructions:
1. Run your Terraform GitHub Action and ensure it completes successfully to destroy all of your infrastructure.  Do double check in the AWS Console (UI) that the resources have been deleted.
2. Run terraform destroy locally to destroy your remote state and GitHub IAM role.
