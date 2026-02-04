#!/bin/bash
set -e

# 1. Update and Install Docker
apt-get update -y
apt-get install -y docker.io curl
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu

# 2. Securely fetch AWS Metadata using IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

# Clean VPC ID Fetch
MAC=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -n1)
VPC_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC}vpc-id)

# 3. Pull and Run
docker pull yaelitrovnik/flask-aws-monitor:latest

# We pass the metadata into the container
# Note: For SSH_KEY_PATH, we show the name defined in Terraform for the dashboard
docker run -d \
  --name flask-dashboard \
  -p 5001:5001 \
  -e INSTANCE_TYPE="$INSTANCE_TYPE" \
  -e VPC_ID="$VPC_ID" \
  -e REGION="$REGION" \
  -e SSH_KEY_PATH="AWS KeyPair: builder_key" \
  --restart always \
  yaelitrovnik/flask-aws-monitor:latest