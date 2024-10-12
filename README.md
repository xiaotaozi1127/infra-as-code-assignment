# Infra as Code - Assignment for IaC Course

## Overview
We use terraform to deploy the infra resources. It will deploy api gateway which integrated with lambda functions to register and verify users. The lambda function is written in python and uses dynamodb to store the user data.   
You can check the `src` directory for the lambda function code and `terraform` directory for the terraform configuration.

### Architecture
![Architecture](./images/assignment.png)

### Deployment
In order to deploy the infrastructure with GHA workflow, we need to grant the permission to the GHA workflow. so, we created `tw-infra-taohui-github-actions-role` first.
please check the `terraform/github_iam_role` for more details. you need to use local backend to manage the state and create the role first.  
For other aws resources, which include api-gateway, lambda functions, s3 and dynamodb table, we use remote backend to manage the state. 

**Pre-requisites**
- create s3 bucket for terraform state: tw-infra-taohui-tfstate
- create dynamodb table for terraform state lock: tw-infra-taohui-tfstate-locks

**Workflows**
- deploy (triggered by push to main branch)
  - configure aws credentials
  - format terraform code
  - lint terraform code
  - identify security issues with checkov
  - deploy the infra resources
- destroy (manually triggered)
  - destroy the infra resources

### Update Lambda functions Logic
We have 2 lambda functions in this project.
- The lambda function `register_user` is used to register the user and store the user data in dynamodb table. 
- The lambda function `verify_user` is used to verify the user by checking the user data in dynamodb table.

When we configure the terraform for lambda function, we need to provide the zip file for the lambda function.
The following commands are used to generate the zip file for the lambda function. Please upload the zip file whenever lambda function logic changes.
```bash
cd src
zip -r register_user.zip register_user.py
zip -r verify_user.zip verify_user.py
mv register_user.zip ../register_user.zip
mv verify_user.zip ../verify_user.zip
```

### Try Lambda Functions
We choose Lambda Proxy Integration with AWS API Gateway, it means that API Gateway will pass the entire HTTP request to our Lambda function as a single event object. This integration allows you to handle the entire request and response cycle within your Lambda function.

If you want to test the lambda functions from aws console, you can select template as `API Gateway HTTP API` and modify `queryStringParameters`, add `userid` param should be good, like below:
```json
{
  "queryStringParameters": {
    "userid": "taohui"
  }
}
```
you can check the detailed log in cloudwatch log group `/aws/lambda/tw-infra-taohui_register_user` and `/aws/lambda/tw-infra-taohui_verify_user`

### Try API Gateway APIs
If you want to test from api gateway directly, you need to find invoke url from the api stage. The invoke url is like `https://{api-id}.execute-api.ap-southeast-2.amazonaws.com/{stage_name}/`

Example API for register user: `https://bcgtiuk4z7.execute-api.ap-southeast-2.amazonaws.com/default/register`, you can test it like below:
```
curl -X POST https://bcgtiuk4z7.execute-api.ap-southeast-2.amazonaws.com/default/register?userid=taohui
```
Then, you should receive the response like below:
```
{
    "message": "Registered User Successfully"
}
```

Example API for verify user: `https://rq5nizcyyi.execute-api.ap-southeast-2.amazonaws.com/default`, you can test it like below:
```
curl https://rq5nizcyyi.execute-api.ap-southeast-2.amazonaws.com/default?userid=taohui
```
On successfully verification, you should receive the [index html page](terraform/index.html) from s3. 
However, if you try to verify a user that is not registered, [error html page](terraform/error.html) is fetched from s3.   

you can check the detailed log in cloudwatch log group `API-Gateway-Execution-Logs_{rest-api-id}/{stage_name}`
> AWS API Gateway automatically creates log groups following this naming convention when you enable logging for your API. If you create a custom log group with a different name, API Gateway may not send logs to that group, leading to missing logs.









