#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Enable debug mode
DEBUG=true

# Function to print section header
print_header() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n" >&2
}

# Function to print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}" >&2
}

# Function to print error message
print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

# Function to print debug message
print_debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${YELLOW}DEBUG: $1${NC}" >&2
    fi
}

# Get AWS account ID
get_aws_account_id() {
    print_debug "Checking AWS credentials..."
    aws_account_id=$(aws sts get-caller-identity --query Account --output text 2>&1)
    result=$?
    
    print_debug "AWS CLI Result: $result"
    print_debug "AWS Account ID Output: $aws_account_id"
    
    if [ $result -ne 0 ] || [ -z "$aws_account_id" ]; then
        print_error "Failed to get AWS account ID. Make sure you have AWS CLI configured with valid credentials."
        print_error "Error: $aws_account_id"
        print_debug "AWS CLI not properly configured or no internet connection."
        return 1
    fi
    
    # Validate account ID format (12 digits)
    if ! [[ $aws_account_id =~ ^[0-9]{12}$ ]]; then
        print_error "Invalid AWS account ID format: $aws_account_id"
        print_debug "Expected 12 digits, got: $aws_account_id"
        return 1
    fi
    
    print_success "AWS Account ID: $aws_account_id"
    echo "$aws_account_id"
    return 0
}

# Get S3 bucket name
get_s3_bucket_name() {
    print_header "Getting S3 Bucket Name for Frontend"
    print_debug "Changing to terraform/main directory"
    
    if [ ! -d "terraform/main" ]; then
        print_error "Directory terraform/main does not exist!"
        print_debug "Current directory: $(pwd)"
        return 1
    fi
    
    cd terraform/main
    print_debug "Getting S3 bucket name..."
    
    # Get only the raw value without any formatting or extra messages
    s3_bucket=$(terraform output -raw frontend_bucket_name 2>/dev/null)
    result=$?
    
    print_debug "Terraform output result: $result"
    print_debug "S3 bucket name: $s3_bucket"
    
    if [ $result -ne 0 ] || [ -z "$s3_bucket" ]; then
        print_error "Failed to get S3 bucket name from Terraform output."
        print_error "If you haven't applied the Terraform configuration yet, please run option 1 first."
        cd ../../
        return 1
    fi
    
    print_success "S3 Bucket Name: $s3_bucket"
    cd ../../
    echo "$s3_bucket"
    return 0
}

# Get ECR Repository URL
get_ecr_repo_url() {
    print_header "Getting ECR Repository URL"
    print_debug "Changing to terraform/main directory"
    
    if [ ! -d "terraform/main" ]; then
        print_error "Directory terraform/main does not exist!"
        print_debug "Current directory: $(pwd)"
        return 1
    fi
    
    cd terraform/main
    print_debug "Getting Terraform outputs..."
    
    # Get only the raw value without any formatting or extra messages
    ecr_url=$(terraform output -raw api_repository_url 2>/dev/null)
    result=$?
    
    print_debug "Terraform output result: $result"
    print_debug "ECR URL: $ecr_url"
    
    if [ $result -ne 0 ] || [ -z "$ecr_url" ]; then
        print_error "Failed to get ECR repository URL from Terraform output."
        print_error "If you haven't applied the Terraform configuration yet, please run option 1 first."
        cd ../../
        return 1
    fi
    
    print_success "ECR Repository URL: $ecr_url"
    cd ../../
    echo "$ecr_url"
    return 0
}

# Deploy Terraform Infrastructure
deploy_terraform() {
    print_header "Deploying Infrastructure with Terraform"
    
    if [ ! -d "terraform/main" ]; then
        print_error "Directory terraform/main does not exist!"
        print_debug "Current directory: $(pwd)"
        return 1
    fi
    
    cd terraform/main
    
    echo "Initializing Terraform..."
    terraform_init=$(terraform init 2>&1)
    result=$?
    
    print_debug "Terraform init result: $result"
    print_debug "Terraform init output: $terraform_init"
    
    if [ $result -ne 0 ]; then
        print_error "Terraform initialization failed."
        print_error "Error: $terraform_init"
        cd ../../
        return 1
    fi
    
    print_success "Terraform initialized successfully."
    
    echo "Applying Terraform configuration..."
    terraform apply
    
    if [ $? -ne 0 ]; then
        print_error "Terraform apply failed."
        cd ../../
        return 1
    fi
    
    print_success "Terraform apply completed successfully."
    cd ../../
    return 0
}

# Build and push backend Docker image
build_push_backend() {
    print_header "Building and Pushing Backend Docker Image"
    
    print_debug "Current directory: $(pwd)"
    
    # Get AWS account ID - capture only the clean output
    print_debug "Getting AWS account ID..."
    aws_account_id=$(get_aws_account_id)
    aws_result=$?
    
    print_debug "get_aws_account_id result: $aws_result"
    print_debug "AWS Account ID: $aws_account_id"
    
    if [ $aws_result -ne 0 ]; then
        print_error "Failed to get AWS account ID. Cannot continue."
        return 1
    fi
    
    # Get ECR Repository URL - only once and save it
    print_debug "Getting ECR Repository URL..."
    ecr_url=$(get_ecr_repo_url)
    ecr_result=$?
    
    print_debug "get_ecr_repo_url result: $ecr_result"
    print_debug "ECR URL: $ecr_url"
    
    if [ $ecr_result -ne 0 ]; then
        print_error "Failed to get ECR repository URL. Cannot continue."
        return 1
    fi
    
    # Log in to ECR - directly use AWS account ID without debug output
    echo "Logging in to ECR..."
    print_debug "Running AWS ECR login command..."
    print_debug "Using AWS account ID: $aws_account_id"
    print_debug "ECR URL: $aws_account_id.dkr.ecr.us-west-2.amazonaws.com"
    
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "$aws_account_id.dkr.ecr.us-west-2.amazonaws.com"
    login_result=$?
    
    if [ $login_result -ne 0 ]; then
        print_error "Failed to log in to ECR."
        return 1
    fi
    
    print_success "Logged in to ECR successfully."
    
    # Build backend Docker image
    if [ ! -d "backend" ]; then
        print_error "Directory 'backend' does not exist!"
        print_debug "Current directory: $(pwd)"
        return 1
    fi
    
    echo "Building backend Docker image..."
    cd backend
    print_debug "Changed to backend directory: $(pwd)"
    
    docker build --platform linux/amd64 -t demo-api .
    build_result=$?
    
    if [ $build_result -ne 0 ]; then
        print_error "Docker build failed."
        cd ..
        return 1
    fi
    
    print_success "Backend Docker image built successfully."
    
    # Tag and push the image - use the saved ECR URL
    echo "Tagging and pushing image to ECR..."
    print_debug "Tagging image as: $ecr_url:latest"
    
    docker tag demo-api:latest "$ecr_url:latest"
    tag_result=$?
    
    if [ $tag_result -ne 0 ]; then
        print_error "Failed to tag Docker image."
        cd ..
        return 1
    fi
    
    docker push "$ecr_url:latest"
    push_result=$?
    
    if [ $push_result -ne 0 ]; then
        print_error "Failed to push image to ECR."
        cd ..
        return 1
    fi
    
    print_success "Image pushed to ECR successfully."
    cd ..
    return 0
}

# Build and deploy React frontend
build_deploy_frontend() {
    print_header "Building and Deploying React Frontend"
    
    print_debug "Current directory: $(pwd)"
    
    # Get S3 bucket name
    print_debug "Getting S3 bucket name..."
    s3_bucket=$(get_s3_bucket_name)
    s3_result=$?
    
    print_debug "get_s3_bucket_name result: $s3_result"
    print_debug "S3 bucket name: $s3_bucket"
    
    if [ $s3_result -ne 0 ]; then
        print_error "Failed to get S3 bucket name. Cannot continue."
        return 1
    fi
    
    # Get API endpoint for environment variable
    cd terraform/main
    api_endpoint=$(terraform output -raw api_endpoint 2>/dev/null)
    api_result=$?
    cd ../../
    
    if [ $api_result -ne 0 ] || [ -z "$api_endpoint" ]; then
        print_error "Failed to get API endpoint."
        return 1
    fi
    
    print_debug "API endpoint: $api_endpoint"
    
    # Build React frontend
    if [ ! -d "frontend" ]; then
        print_error "Directory 'frontend' does not exist!"
        print_debug "Current directory: $(pwd)"
        return 1
    fi
    
    echo "Building React frontend..."
    cd frontend
    print_debug "Changed to frontend directory: $(pwd)"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
        if [ $? -ne 0 ]; then
            print_error "Failed to install dependencies."
            cd ..
            return 1
        fi
    fi
    
    # Set the API endpoint environment variable for the build
    echo "REACT_APP_API_ENDPOINT=$api_endpoint" > .env
    print_debug "Created .env file with API endpoint: $api_endpoint"
    
    # Build the React app
    echo "Running build..."
    npm run build
    build_result=$?
    
    if [ $build_result -ne 0 ]; then
        print_error "React build failed."
        cd ..
        return 1
    fi
    
    print_success "React frontend built successfully."
    
    # Deploy to S3
    echo "Deploying to S3 bucket: $s3_bucket..."
    aws s3 sync build/ s3://$s3_bucket/ --delete
    sync_result=$?
    
    if [ $sync_result -ne 0 ]; then
        print_error "Failed to sync files to S3."
        cd ..
        return 1
    fi
    
    print_success "Frontend deployed successfully to S3 bucket: $s3_bucket"
    cd ..
    return 0
}

# Wait for ECS service to be stable
wait_for_ecs() {
    print_header "Waiting for ECS Service to Stabilize"
    
    echo "This may take a few minutes..."
    attempts=0
    max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        status_output=$(aws ecs describe-services --cluster demo-cluster --services demo-api --region us-west-2 --query 'services[0].deployments[0].runningCount' --output text 2>&1)
        status_result=$?
        
        print_debug "ECS status result: $status_result"
        print_debug "ECS status output: $status_output"
        
        if [ $status_result -ne 0 ]; then
            print_error "Failed to get ECS service status."
            print_error "Error: $status_output"
            return 1
        fi
        
        desired_output=$(aws ecs describe-services --cluster demo-cluster --services demo-api --region us-west-2 --query 'services[0].deployments[0].desiredCount' --output text 2>&1)
        desired_result=$?
        
        print_debug "ECS desired result: $desired_result"
        print_debug "ECS desired output: $desired_output"
        
        if [ $desired_result -ne 0 ]; then
            print_error "Failed to get ECS service desired count."
            print_error "Error: $desired_output"
            return 1
        fi
        
        status=$status_output
        desired=$desired_output
        
        echo "Running tasks: $status / $desired"
        
        if [ "$status" == "$desired" ] && [ "$status" -gt 0 ]; then
            print_success "ECS service is now stable with $status running tasks."
            return 0
        fi
        
        attempts=$((attempts + 1))
        echo "Waiting for ECS service to stabilize (attempt $attempts/$max_attempts)..."
        sleep 10
    done
    
    print_error "Timed out waiting for ECS service to stabilize."
    return 1
}

# Display application URLs
display_urls() {
    print_header "Application URLs"
    
    if [ ! -d "terraform/main" ]; then
        print_error "Directory terraform/main does not exist!"
        print_debug "Current directory: $(pwd)"
        return 1
    fi
    
    cd terraform/main
    api_endpoint=$(terraform output -raw api_endpoint 2>/dev/null)
    api_result=$?
    
    print_debug "API endpoint result: $api_result"
    print_debug "API endpoint output: $api_endpoint"
    
    if [ $api_result -ne 0 ]; then
        print_error "Failed to get API endpoint."
        print_error "Error: $api_endpoint"
        cd ../../
        return 1
    fi
    
    frontend_url=$(terraform output -raw frontend_url 2>/dev/null)
    frontend_result=$?
    
    print_debug "Frontend URL result: $frontend_result"
    print_debug "Frontend URL output: $frontend_url"
    
    if [ $frontend_result -ne 0 ]; then
        print_error "Failed to get frontend URL."
        print_error "Error: $frontend_url"
        cd ../../
        return 1
    fi
    
    cd ../../
    
    if [ -z "$api_endpoint" ] || [ -z "$frontend_url" ]; then
        print_error "Failed to get application URLs from Terraform output."
        print_error "If you haven't applied the Terraform configuration yet, please run option 1 first."
        return 1
    fi
    
    echo -e "Backend API: ${GREEN}$api_endpoint${NC}"
    echo -e "Frontend: ${GREEN}$frontend_url${NC}"
    
    echo -e "\nTest the API with:"
    echo -e "curl $api_endpoint/health"
    
    echo -e "\nAccess the frontend at:"
    echo -e "$frontend_url"
    
    return 0
}

# Destroy all resources
destroy_resources() {
    print_header "Destroying All Resources"
    
    echo "This will destroy all resources created by Terraform. This action cannot be undone."
    read -p "Are you sure you want to continue? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo "Destroy cancelled."
        return 0
    fi
    
    if [ ! -d "terraform/main" ]; then
        print_error "Directory terraform/main does not exist!"
        print_debug "Current directory: $(pwd)"
        return 1
    fi
    
    cd terraform/main
    terraform destroy
    
    if [ $? -ne 0 ]; then
        print_error "Terraform destroy failed."
        cd ../../
        return 1
    fi
    
    print_success "All resources destroyed successfully."
    cd ../../
    return 0
}

# Check AWS configuration
check_aws_config() {
    print_header "Checking AWS Configuration"
    print_debug "Running AWS configure list..."
    
    aws_config=$(aws configure list 2>&1)
    config_result=$?
    
    if [ $config_result -ne 0 ]; then
        print_error "AWS CLI not properly configured."
        print_error "Error: $aws_config"
        return 1
    fi
    
    echo "AWS Configuration:"
    echo "$aws_config"
    
    print_debug "Checking AWS CLI version..."
    aws_version=$(aws --version 2>&1)
    print_debug "AWS CLI version: $aws_version"
    
    print_debug "Testing AWS connectivity..."
    test_connection=$(aws sts get-caller-identity 2>&1)
    conn_result=$?
    
    if [ $conn_result -ne 0 ]; then
        print_error "Failed to connect to AWS."
        print_error "Error: $test_connection"
        print_error "Please configure AWS CLI with valid credentials:"
        print_error "Run 'aws configure' and enter your AWS Access Key, Secret Key, region (us-west-2), and output format (json)."
        return 1
    fi
    
    print_success "AWS Configuration is valid."
    echo "$test_connection"
    return 0
}

# Main menu
while true; do
    print_header "Deployment Options"
    echo "1) Deploy Terraform Infrastructure"
    echo "2) Build and Push Backend Docker Image"
    echo "3) Build and Deploy React Frontend"
    echo "4) Wait for ECS Service to Stabilize"
    echo "5) Display Application URLs"
    echo "6) Destroy All Resources"
    echo "7) Check AWS Configuration"
    echo "0) Exit"
    
    read -p "Choose an option (0-7): " option
    
    case $option in
        1)
            deploy_terraform
            ;;
        2)
            build_push_backend
            ;;
        3)
            build_deploy_frontend
            ;;
        4)
            wait_for_ecs
            ;;
        5)
            display_urls
            ;;
        6)
            destroy_resources
            ;;
        7)
            check_aws_config
            ;;
        0)
            print_header "Exiting Deployment Script"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose a number between 0 and 7."
            ;;
    esac
done 