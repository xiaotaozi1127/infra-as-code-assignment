# Infra as Code - Assignment for IaC Course

## Overview
It provides api gateway to register and verify users. The api gateway is integrated with lambda function to handle the requests. The lambda function is written in python and it uses dynamodb to store the user data.

### Architecture
![Architecture](./images/assignment.png)


### Pre-requisites
- create s3 bucket for terraform state: tw-infra-taohui-tfstate
- create dynamodb table for terraform state lock: tw-infra-tfstate-locks-taohui

### Lambda Proxy Integration
When you choose Lambda Proxy Integration with AWS API Gateway, it means that API Gateway will pass the entire HTTP request to your Lambda function as a single event object. This integration allows you to handle the entire request and response cycle within your Lambda function, giving you more control over the processing of requests.
