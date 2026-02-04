#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# 1. Update and Install Docker for Ubuntu
apt-get update -y
apt-get install -y docker.io curl
systemctl start docker
systemctl enable docker

# Add the default ubuntu user to the docker group
usermod -a -G docker ubuntu

# 2. Securely fetch AWS Metadata using IMDSv2 (Required for your app.py)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)
VPC_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/)/vpc-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

# 3. Pull the Image from Docker Hub
# Note: Ensure the image name matches what Jenkins pushes
docker pull yaelitrovnik/flask-aws-monitor:latest

# 4. Run the Container
# We pass AWS metadata into the container as Environment Variables
docker run -d \
  --name flask-dashboard \
  -p 5001:5001 \
  -e INSTANCE_TYPE="$INSTANCE_TYPE" \
  -e VPC_ID="$VPC_ID" \
  -e REGION="$REGION" \
  -e SSH_KEY_PATH="/home/ubuntu/.ssh/builder_key" \
  --restart always \
  yaelitrovnik/flask-aws-monitor:latest