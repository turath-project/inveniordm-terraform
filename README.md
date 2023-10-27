## Preparations and usage of this terraform

### Tools Used

* [Terraform](https://www.terraform.io/)
* [Sops](https://github.com/mozilla/sops)
* [AWS CLI](https://aws.amazon.com/cli/)

### Manual init steps for terraform preparation (one time only)
- creat IAM user with `AdministratorAccess` AWS managed permission policy
- creating S3 bucket for terraform backend. Terraform will keep the tfstate file in specified S3 bucket
- follow "# manual add value" comments in 0-main.tf file
- All configs ruled by "secrets.enc.yml" and "terraform.enc.tfvars.json" files
- create KMS key for further encrypt/decrypt the files with sensitive data. Used in connection with `sops` by export SOPS_KMS_ARN=arn:aws:kms:*

## Services Used

* [ALB - Application Load Balancer](https://aws.amazon.com/elasticloadbalancing/application-load-balancer/): internal connection endpoint to the application
* [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/): provision, manage, and deploy public and private SSL/TLS certificates
* [ECR - Elastic Container Registry](https://aws.amazon.com/ecr/): private Docker registry to hold our application images (uploaded from Circle CI)
* [ECS - Elastic Container Service](https://aws.amazon.com/ecs/): container orchestration
* [ECS Service](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html): run and maintain a specified number of instances of a task definition
* [RDS](https://aws.amazon.com/rds/): Amazon Relational Database Service
* [Fargate](https://aws.amazon.com/fargate/): serverless compute platform/engine
* [KMS - Key Management Service](https://aws.amazon.com/kms/): managed service handling encryption
* [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html): network address translation service
* [Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html): secure, hierarchical storage for secrets management
* [Route 53](https://aws.amazon.com/route53/): highly available and scalable cloud Domain Name System (DNS) web service
* [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/): Provision and manage SSL/TLS certificates with AWS services and connected resources
* [S3 - Simple Storage Service](https://aws.amazon.com/s3/): object storage
* [Task Definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html): task definition is a text file, that describes one or more containers, that form service
* [VPC - Virtual Private Cloud](https://aws.amazon.com/vpc/): isolated network
* [VPC Subnet](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html): range of IP addresses in VPC
* [Amazon MQ](https://aws.amazon.com/de/amazon-mq/): Managed Message Broker Service for ActiveMQ
* [Amazon ElastiCache](https://aws.amazon.com/elasticache/?nc1=h_ls): Amazon ElastiCache is a fully managed, Redis- and Memcached-compatible service delivering real-time, cost-optimized performance for modern applications.
* [Amazon Open Search](https://aws.amazon.com/opensearch-service/): OpenSearch Service makes it easy for you to perform interactive log analytics, real-time application monitoring, website search, and more.
* [Minio](https://min.io/): MinIO is a high-performance, S3 compatible object store.

## General information
| Env                  | Dev                                                  |
|----------------------|------------------------------------------------------|
| AWS account          | xxxxxxxxxxxx (Invenio)                               |
| Region               | choose your region                                   |
| Terraform backend S3 | create bucket for terraform state by manual          |

## How to interact with terraform locally:
- Configure AWS profile withing AWS cli. Use `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` of any IAM user with AdministratorAccess policy.
- decrypt files with the help of `sops`:
```
sops -d terraform.enc.tfvars.json > terraform.tfvars.json
sops -d secrets.enc.yml > secrets.yml
```
- run:
```
terraform init
terraform validate
terraform plan/apply
```

## Environment variables
To update env. variable do next:
- execute `sops terraform.enc.tfvars.json` or `sops secrets.enc.yml`, make changes and save file.
- apply changes `terraform plan/apply`
- in order to apply the env. variable(s) changes on the ECS service side either in AWS ECS, manually force new deployment for specified service.

