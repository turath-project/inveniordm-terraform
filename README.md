## Preparations and usage of this terraform

### Tools Used

* [Terraform](https://www.terraform.io/)
* [Sops](https://github.com/mozilla/sops)
* [AWS CLI](https://aws.amazon.com/cli/)

### Manual init steps for terraform preparation (one time only)
- creat IAM user with `AdministratorAccess` AWS managed permission policy
- creating S3 bucket for terraform backend. Terraform will keep the tfstate file in specified S3 bucket
- follow `# manual add value` comments in `0-main.tf` file
- All configs ruled by `secrets.enc.yml` and `terraform.enc.tfvars.json` files
- create KMS key for further encrypt/decrypt the files with sensitive data. Used in connection with `sops` by export `SOPS_KMS_ARN=arn:aws:kms:*****`

## Services Used

* [ALB - Application Load Balancer](https://aws.amazon.com/elasticloadbalancing/application-load-balancer/): internal connection endpoint to the application
* [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/): provision, manage, and deploy public and private SSL/TLS certificates
* [ECR - Elastic Container Registry](https://aws.amazon.com/ecr/): private Docker registry to hold our application images (uploaded from Circle CI)
* [ECS - Elastic Container Service](https://aws.amazon.com/ecs/): container orchestration
* [ECS Service](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html): run and maintain a specified number of instances of a task definition
* [RDS](https://aws.amazon.com/rds/): Amazon Relational Database Service
* [Fargate](https://aws.amazon.com/fargate/): serverless compute platform/engine
* [CloudFront](https://aws.amazon.com/cloudfront/): Amazon CloudFront is a content delivery network (CDN) service built for high performance, security, and developer convenience.
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
### App code changes and preparation for deploying to ECS
- after we initialize and generates project structure (_https://inveniordm.docs.cern.ch/install/scaffold/_) we need to change this lines:
  `socket=0.0.0.0:5000` to `http=0.0.0.0:5000`
  in 2 files: `docker/uwsgi/uwsgi_rest.ini` and `docker/uwsgi/uwsgi_ui.ini`
- start project locally in docker and cp `/opt/invenio/var/instance/static` folder from docker container with api to S3:
  for that run script: `upload_to_s3.sh`. Or if you init project without docker with "Select file_storage: local" option you need to copy static files into S3 bucket manually
- all this actions can be applied only after s3 bucket creation with `terraform apply` command
- apply terraform and wait till mq, elk, rds and other services will deployed with creating their endpoints and add it into `secrets.yml` and `terraform.tfvars`
- change in `invenio.cfg` file lines with "`# TODO:`" tag with your needed values. For example:
  `APP_ALLOWED_HOSTS` to `None` value - `APP_ALLOWED_HOSTS = None`
  Without this changes, app will not working. This hardcoded values need to be changed by developers
- We prepare logic to centralize app environments with parameter store, but at this moment it depends on `invenio.cfg` file setup
- after preparing all env variables for app - apply terraform again. This will redeploy ECS services with added env variables

## Environment variables
To update environment variables do next:
- execute `sops terraform.enc.tfvars.json` or `sops secrets.enc.yml`, make changes and save file
- apply changes `terraform plan/apply`
- in order to apply the environment variable(s) changes on the ECS service side either in AWS ECS, manually force new deployment for specified service

## Additional notes:
Note !!! You need to build, tag and push your images into ECR manually:
Example:
- `docker tag invenio:latest <aws_account_id>.dkr.ecr.eu-north-1.amazonaws.com/invenio-default-api:latest`
[Follow this guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)
- without CI-CD functionality you need to push images every time the app code changes

