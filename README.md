# Terraform Demo Project

This is a simple demo project showcasing how to use Terraform to provision infrastructure for a full-stack application with:

- Python FastAPI backend
- React frontend
- PostgreSQL database

All infrastructure is deployed to AWS.

## Project Structure

```
.
├── terraform/           # Terraform configurations
│   ├── main/            # Main Terraform configuration
│   └── modules/         # Terraform modules
│       ├── vpc/         # VPC module
│       ├── database/    # PostgreSQL database module
│       ├── backend/     # FastAPI backend module
│       └── frontend/    # React frontend module
├── backend/             # FastAPI application code
└── frontend/            # React application code
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Docker](https://www.docker.com/get-started) (for building application images)

## Required AWS Permissions

Your AWS user or role needs the following permissions to deploy this project:

### VPC Permissions
- `ec2:CreateVpc`
- `ec2:CreateSubnet`
- `ec2:CreateInternetGateway`
- `ec2:CreateRouteTable`
- `ec2:CreateRoute`
- `ec2:AttachInternetGateway`
- `ec2:AssociateRouteTable`
- `ec2:DescribeVpcs`
- `ec2:DescribeSubnets`
- `ec2:DescribeInternetGateways`
- `ec2:DescribeRouteTables`
- `ec2:DescribeAvailabilityZones`

### Database Permissions
- `rds:CreateDBInstance`
- `rds:CreateDBSubnetGroup`
- `rds:DescribeDBInstances`
- `rds:DescribeDBSubnetGroups`
- `rds:ModifyDBInstance`
- `rds:DeleteDBInstance`
- `rds:DeleteDBSubnetGroup`

### Security Group Permissions
- `ec2:CreateSecurityGroup`
- `ec2:AuthorizeSecurityGroupIngress`
- `ec2:AuthorizeSecurityGroupEgress`
- `ec2:DescribeSecurityGroups`
- `ec2:DeleteSecurityGroup`

### ECR Permissions
- `ecr:CreateRepository`
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`
- `ecr:PutImage`
- `ecr:DescribeRepositories`
- `ecr:DeleteRepository`

### ECS Permissions
- `ecs:CreateCluster`
- `ecs:RegisterTaskDefinition`
- `ecs:CreateService`
- `ecs:DescribeClusters`
- `ecs:DescribeServices`
- `ecs:DescribeTaskDefinition`
- `ecs:DeleteService`
- `ecs:DeleteCluster`
- `ecs:DeregisterTaskDefinition`

### IAM Permissions
- `iam:CreateRole`
- `iam:AttachRolePolicy`
- `iam:PassRole`
- `iam:GetRole`
- `iam:DetachRolePolicy`
- `iam:DeleteRole`

### Load Balancer Permissions
- `elasticloadbalancing:CreateLoadBalancer`
- `elasticloadbalancing:CreateTargetGroup`
- `elasticloadbalancing:CreateListener`
- `elasticloadbalancing:DescribeLoadBalancers`
- `elasticloadbalancing:DescribeTargetGroups`
- `elasticloadbalancing:DescribeListeners`
- `elasticloadbalancing:DeleteLoadBalancer`
- `elasticloadbalancing:DeleteTargetGroup`
- `elasticloadbalancing:DeleteListener`

### S3 Permissions
- `s3:CreateBucket`
- `s3:PutBucketPolicy`
- `s3:PutBucketWebsite`
- `s3:PutBucketPublicAccessBlock`
- `s3:PutObject`
- `s3:GetObject`
- `s3:ListBucket`
- `s3:DeleteBucket`
- `s3:DeleteObject`
- `s3:DeleteBucketPolicy`

### CloudWatch Permissions
- `logs:CreateLogGroup`
- `logs:DescribeLogGroups`
- `logs:DeleteLogGroup`

### Simple Solution
Instead of adding individual permissions, you can use the following AWS managed policies:
- `AmazonVPCFullAccess`
- `AmazonRDSFullAccess`
- `AmazonEC2FullAccess`
- `AmazonECR-FullAccess`
- `AmazonECS-FullAccess`
- `IAMFullAccess`
- `ElasticLoadBalancingFullAccess`
- `AmazonS3FullAccess`
- `CloudWatchLogsFullAccess`

Alternatively, for production environments, create a custom policy with least privilege permissions.

## Getting Started

1. **Initialize Terraform**:

   ```bash
   cd terraform/main
   terraform init
   ```

2. **Deploy the Infrastructure**:

   ```bash
   terraform apply
   ```

   This will create all the necessary infrastructure on AWS.

3. **Build and Push Docker Images**:

   ```bash
   # Build and push backend image
   cd backend
   docker build -t <your-account-id>.dkr.ecr.us-west-2.amazonaws.com/demo-api:latest .
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-west-2.amazonaws.com
   docker push <your-account-id>.dkr.ecr.us-west-2.amazonaws.com/demo-api:latest
   ```

4. **Access the Application**:

   After the infrastructure is deployed, you can access:
   
   - Frontend: Output as `frontend_url` from Terraform
   - Backend API: Output as `api_endpoint` from Terraform

## Cleaning Up

To avoid incurring charges, make sure to destroy the infrastructure when you're done:

```bash
cd terraform/main
terraform destroy
```

## Features

- **VPC**: Isolated network with public and private subnets
- **Database**: PostgreSQL RDS instance in a private subnet
- **Backend**: FastAPI running on ECS Fargate with auto-scaling
- **Frontend**: React app hosted on S3 with CloudFront distribution

## Notes

This is a demo project intended for learning purposes. For a production environment, you should:

1. Add proper authentication and authorization
2. Configure HTTPS
3. Set up monitoring and logging
4. Implement CI/CD pipelines
5. Add more robust error handling and data validation 