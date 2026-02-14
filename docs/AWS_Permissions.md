# AWS Permissions Guide

This document explains the AWS permissions needed to run this project and how to configure them.

---

## 🎯 Overview

Terraform needs specific AWS permissions to create and manage resources. This guide helps you:
1. Understand what permissions are required
2. Create an IAM user for the project
3. Configure credentials securely

---

## 📋 Required AWS Permissions

### Minimum Required Permissions

Terraform will create the following AWS resources:
- **EC2 Instance** (t3.medium Ubuntu server)
- **Security Group** (firewall rules)
- **Key Pair** (SSH access)

To do this, your AWS user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2InstanceManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeInstanceStatus",
        "ec2:ModifyInstanceAttribute",
        "ec2:RebootInstances",
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecurityGroupManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KeyPairManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateKeyPair",
        "ec2:DeleteKeyPair",
        "ec2:DescribeKeyPairs",
        "ec2:ImportKeyPair"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TaggingPermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "NetworkInterfaceInfo",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🔧 Option 1: Create a New IAM User (Recommended)

### Step 1: Access IAM Console

```
1. Log into AWS Console
2. Navigate to: Services → IAM (Identity and Access Management)
3. Click "Users" in the left sidebar
4. Click "Add users"
```

---

### Step 2: Create User

```
User name: jenkins-terraform-user

Select AWS credential type:
☑ Access key - Programmatic access
☐ Password - AWS Management Console access (not needed)

Click "Next: Permissions"
```

---

### Step 3: Attach Permissions

**Method A: Attach Existing Policy (Quick but broader permissions)**
```
1. Click "Attach existing policies directly"
2. Search for and select: AmazonEC2FullAccess
3. Click "Next: Tags"
```

**Method B: Create Custom Policy (More Secure - Recommended)**
```
1. Click "Attach existing policies directly"
2. Click "Create policy"
3. Click JSON tab
4. Paste the JSON policy from the "Required AWS Permissions" section above
5. Click "Review policy"
6. Name: TerraformEC2MinimumPermissions
7. Description: Minimum permissions for Flask AWS Monitor project
8. Click "Create policy"
9. Go back to user creation, refresh the policy list
10. Search for and select: TerraformEC2MinimumPermissions
11. Click "Next: Tags"
```

---

### Step 4: Add Tags (Optional)

```
Key: Project
Value: FlaskAWSMonitor

Key: Purpose
Value: Student-Jenkins-Pipeline

Click "Next: Review"
```

---

### Step 5: Review and Create

```
Review the settings:
- User name: jenkins-terraform-user
- AWS access type: Programmatic access
- Permissions: TerraformEC2MinimumPermissions (or AmazonEC2FullAccess)

Click "Create user"
```

---

### Step 6: Save Credentials

**CRITICAL: This is your only chance to see the secret key!**

```
You will see:
- Access key ID: AKIAIOSFODNN7EXAMPLE
- Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

SAVE THESE IMMEDIATELY:
1. Click "Download .csv" (saves both keys)
2. Store in a secure location (NOT in git repository!)
3. You'll need these for Jenkins configuration

Click "Close"
```

---

## 🔧 Option 2: Use Existing IAM User

If you already have an IAM user:

### Check Existing Permissions

```
1. AWS Console → IAM → Users
2. Click on your user
3. Click "Permissions" tab
4. Verify you have one of:
   - AmazonEC2FullAccess policy
   - A custom policy with the permissions listed above
```

### Create New Access Keys (if needed)

```
1. Click "Security credentials" tab
2. Scroll to "Access keys" section
3. Click "Create access key"
4. Select use case: "Application running outside AWS"
5. Click "Next"
6. Add description: "Jenkins Terraform Key"
7. Click "Create access key"
8. Download the .csv file
9. Store securely
```

---

## 🔐 Security Best Practices

### 1. Never Commit Credentials to Git

Your `.gitignore` already excludes:
```
*.pem
builder_key
builder_key.pub
.env
```

**Also never commit**:
- AWS Access Key ID
- AWS Secret Access Key
- Any CSV files from AWS

---

### 2. Rotate Keys Regularly

```
Best Practice: Rotate AWS keys every 90 days

To rotate:
1. Create new access key in IAM
2. Update Jenkins credentials with new key
3. Test pipeline works with new key
4. Delete old access key in IAM
```

---

### 3. Enable MFA on AWS Root Account

```
Even though you're using IAM users, protect your root account:

1. AWS Console → IAM Dashboard
2. Under "Security recommendations" click "Add MFA"
3. Follow the setup wizard
4. Use Google Authenticator, Authy, or hardware token
```

---

### 4. Use Least Privilege Principle

```
✓ DO: Create custom policy with only needed permissions
✗ DON'T: Use AdministratorAccess for everything

Our custom policy is already minimal:
- Can create/manage EC2, Security Groups, Key Pairs
- Cannot access S3, RDS, Lambda, etc.
```

---

## 🛠️ Configure AWS Credentials in Jenkins

Once you have your Access Key ID and Secret Access Key:

### Step 1: Add to Jenkins

```
Jenkins → Manage Jenkins → Credentials → System → Global credentials

Add Credential 1:
- Kind: Secret text
- Secret: AKIAIOSFODNN7EXAMPLE (your Access Key ID)
- ID: aws-access-key-id
- Description: AWS Access Key

Add Credential 2:
- Kind: Secret text
- Secret: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY (your Secret Key)
- ID: aws-secret-access-key
- Description: AWS Secret Access Key
```

### Step 2: Jenkinsfile Usage

The credentials are automatically used in this stage:

```groovy
stage('Deploy Infrastructure (Terraform)') {
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }
    steps {
        script {
            dir('terraform') {
                sh 'terraform init'
                sh "terraform apply -auto-approve -var='docker_username=${params.DOCKER_USER}'"
            }
        }
    }
}
```

---

## 🧪 Test Your Permissions

Before running the full pipeline, test if your AWS credentials work:

### Test 1: AWS CLI

```bash
# Configure AWS CLI with your credentials
aws configure
# Enter:
# - AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# - AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# - Default region: us-east-2
# - Default output format: json

# Test connection
aws ec2 describe-instances --region us-east-2

# If successful, you should see: "Reservations": []
# (empty list is OK if you have no instances)
```

### Test 2: Terraform Validation

```bash
cd terraform
terraform init
terraform validate

# Should output: "Success! The configuration is valid."
```

### Test 3: Terraform Plan

```bash
terraform plan -var="docker_username=yaelitrovnik"

# Should show:
# Plan: 4 to add, 0 to change, 0 to destroy.
# (Without actually creating anything)
```

---

## 🐛 Troubleshooting Permission Issues

### Error: "UnauthorizedOperation: You are not authorized..."

**Cause**: Missing EC2 permissions

**Solution**:
```
1. AWS Console → IAM → Users → Your User
2. Click "Add permissions" → "Attach existing policies directly"
3. Select: AmazonEC2FullAccess
4. Click "Next: Review" → "Add permissions"
5. Try Terraform again
```

---

### Error: "InvalidKeyPair.NotFound"

**Cause**: Key pair doesn't exist or wrong permissions

**Solution**:
```
This error usually appears on subsequent runs.
Terraform creates the key pair automatically.

If it persists:
1. AWS Console → EC2 → Key Pairs
2. Search for "builder_key"
3. If exists, delete it
4. Run Terraform again
```

---

### Error: "Credential should be scoped to a valid region"

**Cause**: Wrong region specified

**Solution**:
```
Update terraform/variables.tf:

variable "aws_region" {
  default = "us-east-2"  # ← Must match your AWS account region
}
```

---

## 💰 Cost Control with IAM

### Set up Billing Alerts

Even with minimal permissions, prevent unexpected charges:

```
1. AWS Console → Billing Dashboard
2. Click "Budgets" in left menu
3. Click "Create budget"
4. Select "Cost budget"
5. Set amount: $10/month
6. Set alert at: 80% ($8)
7. Enter your email
8. Click "Create budget"
```

### Tag Resources for Cost Tracking

Our Terraform already adds tags:

```hcl
tags = {
  Name = "JBP-Builder-Instance"
}
```

You can view costs by tag:
```
Billing Dashboard → Cost Explorer → Tags
```

---

## 📊 Summary Checklist

Before running the pipeline, verify:

```
AWS Account Setup:
☐ IAM user created with programmatic access
☐ User has EC2 permissions (custom policy or EC2FullAccess)
☐ Access Key ID obtained and saved securely
☐ Secret Access Key obtained and saved securely
☐ Billing alerts configured

Jenkins Configuration:
☐ Credential 'aws-access-key-id' added with correct ID
☐ Credential 'aws-secret-access-key' added with correct ID
☐ Both credentials are type: "Secret text"
☐ Both credentials have scope: "Global"

Security:
☐ Root account has MFA enabled
☐ Credentials not committed to git
☐ .gitignore includes *.pem and credential files
☐ Access keys stored in secure location (not Desktop!)

Testing:
☐ AWS CLI configured and tested
☐ terraform init successful
☐ terraform validate successful
☐ terraform plan runs without errors
```

---

## 🔄 Credential Rotation Schedule

Recommended schedule for this project:

| Item | Frequency | Action |
|------|-----------|--------|
| Access Keys | Every 90 days | Create new, update Jenkins, delete old |
| Review Permissions | Monthly | Verify user still needs same access |
| Check for unused keys | Weekly | AWS IAM Dashboard shows last used date |
| Password (if console access) | Every 30 days | Change in AWS console |

---

## 📞 Additional Resources

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
- [AWS Access Keys Management](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

---

**Remember**: Your AWS credentials are like your house keys. Treat them with the same level of security! 🔐