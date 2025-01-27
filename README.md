# tf-cf-api-stack example

## Getting started

### Pre-requirements
You need to have these tools installed, already tested on a Linux Debian machine.
* git
* terraform >= 1.8.5


### Clone Repo
`git clone git@github.com:open-servus/tf-cf-api-stack.git`

`cd tf-cf-api-stack/`

### Add AWS Auth
Option 1: Set AWS environment variables
export the AWS Access & Secret key

Option 2: Add a profile to your AWS credentials file

### Run Terraform
```
terraform init

terraform select workspace dev ##suggest to use workspace

terraform plan

terraform apply
```

## Diagram Layout

Here’s a high level architecture diagram:
```
+---------------------+
| Cloudfront          |
+---------------------+
        |
        v
+-------------------+
|       VPC         |
| +---------------+ |
| | Private Subnet| |
| | - VPC Origin  | |
| | - Internal NLB| |
| | - VPC Endpoint| |
| +---------------+ |
+-------------------+
        |
        v
+---------------------+
| Private API Gateway |
+---------------------+
```