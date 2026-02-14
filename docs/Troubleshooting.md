# Troubleshooting Guide

This guide covers common issues you might encounter when running the Flask AWS Monitor project.

---

## 🎯 Quick Diagnosis

**Use this decision tree to find your issue quickly:**

```
Is your problem during:

1. Jenkins Build/Pipeline Issues → See "Jenkins Pipeline Errors"
2. Docker Build/Push → See "Docker Issues"
3. Terraform Infrastructure → See "Terraform Errors"
4. Application Access → See "Dashboard Access Issues"
5. AWS Permissions → See "AWS Permission Errors"
```

---

## 🔧 Jenkins Pipeline Errors

### Error 1: "Credential 'dockerhub-credentials' could not be found"

**Symptom:**
```
ERROR: Credentials 'dockerhub-credentials' could not be found
```

**Cause:** Jenkins credential ID doesn't match the Jenkinsfile reference

**Solution:**
```
1. Go to: Jenkins → Manage Jenkins → Credentials → System → Global
2. Check your Docker credential
3. Click on it and verify the ID field shows: dockerhub-credentials
4. If different, either:
   a) Change the ID to match "dockerhub-credentials", OR
   b) Update Jenkinsfile line:
      DOCKER_CREDS = credentials('dockerhub-credentials')
                                   ^^^^^^^^^^^^^^^^^^^^
                                   Change to your ID
```

---

### Error 2: "docker: command not found"

**Symptom:**
```
/var/lib/jenkins/workspace/[...]: line 1: docker: command not found
```

**Cause:** Docker is not installed on Jenkins server or Jenkins user can't access it

**Solution:**
```bash
# SSH into Jenkins server

# Check if Docker is installed
docker --version

# If not installed:
sudo apt-get update
sudo apt-get install -y docker.io

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# IMPORTANT: Logout and login again for group changes to take effect
```

---

### Error 3: "terraform: command not found"

**Symptom:**
```
terraform: command not found
```

**Cause:** Terraform is not installed on Jenkins server

**Solution:**
```bash
# SSH into Jenkins server

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
sudo apt-get install unzip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Should output: Terraform v1.6.0
```

---

### Error 4: Pipeline Freezes at "Waiting for Input"

**Symptom:**
Pipeline stuck showing "Paused for Input"

**Cause:** Unexpected `input` step in Jenkinsfile

**Solution:**
```
1. Check console output for input message
2. In Jenkins UI, you'll see a prompt - click "Proceed" or "Abort"
3. If you want to remove this (it's not in our Jenkinsfile by default):
   - Edit Jenkinsfile
   - Remove any 'input' steps
   - Commit and push
```

---

### Error 5: "ERROR: script returned exit code 1"

**Symptom:**
```
ERROR: script returned exit code 1
Build step 'Execute shell' marked build as failure
```

**Cause:** A shell command in the Jenkinsfile failed

**Solution:**
```
1. Read the console output ABOVE this error
2. Look for the actual error message (usually a few lines up)
3. Common causes:
   - Docker build failed → Check Dockerfile syntax
   - Terraform apply failed → Check AWS permissions
   - pip install failed → Check requirements.txt
```

---

## 🐳 Docker Issues

### Error 6: "Cannot connect to Docker daemon"

**Symptom:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
Is the docker daemon running?
```

**Cause:** Docker service is not running

**Solution:**
```bash
# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify it's running
sudo systemctl status docker
# Should show: Active: active (running)

# Test Docker
docker ps
# Should show empty list (or running containers)
```

---

### Error 7: "unauthorized: authentication required"

**Symptom:**
```
docker push yaelitrovnik/flask-aws-monitor:latest
unauthorized: authentication required
```

**Cause:** Not logged into Docker Hub, or wrong credentials

**Solution:**
```
Check Jenkins credential:
1. Jenkins → Credentials → dockerhub-credentials
2. Verify username and password are correct
3. Test manually:
   docker login -u <username>
   # Enter password
   # Should show: "Login Succeeded"
```

---

### Error 8: "manifest for image not found"

**Symptom:**
```
Error: manifest for yaelitrovnik/flask-aws-monitor:latest not found
```

**Cause:** Docker image doesn't exist in Docker Hub

**Solution:**
```
If you're the professor using student's image:
1. Verify the student pushed their image:
   - Go to: https://hub.docker.com/r/yaelitrovnik/flask-aws-monitor
   - Check if the image exists

If you're building your own:
1. Make sure DOCKER_USER parameter matches your Docker Hub username
2. Make sure the previous "Push to Docker Hub" stage succeeded
3. Check Docker Hub web interface to verify the push worked
```

---

### Error 9: "no space left on device"

**Symptom:**
```
Error: no space left on device
```

**Cause:** Jenkins server disk is full (usually from old Docker images)

**Solution:**
```bash
# SSH into Jenkins server

# Check disk space
df -h
# Look for partition at 100%

# Clean up Docker
docker system prune -a -f --volumes

# This removes:
# - Stopped containers
# - Unused networks
# - Dangling images
# - Build cache

# Verify space freed
df -h
```

---

## 🏗️ Terraform Errors

### Error 10: "Error launching source instance: UnauthorizedOperation"

**Symptom:**
```
Error: Error launching source instance: UnauthorizedOperation: 
You are not authorized to perform this operation.
```

**Cause:** AWS credentials lack necessary permissions

**Solution:**
```
1. Verify credentials in Jenkins:
   - Credentials → aws-access-key-id → Check value
   - Credentials → aws-secret-access-key → Check value

2. Test AWS CLI:
   aws ec2 describe-instances --region us-east-2
   # Should not give "Unauthorized" error

3. Add permissions to IAM user:
   AWS Console → IAM → Users → Your User
   Attach policy: AmazonEC2FullAccess

4. See AWS_PERMISSIONS.md for detailed setup
```

---

### Error 11: "Error: Invalid AMI ID"

**Symptom:**
```
Error: Error launching source instance: InvalidAMIID.NotFound: 
The image id '[ami-09040d770ff222417]' does not exist
```

**Cause:** AMI ID is region-specific, you're using wrong region

**Solution:**
```
Option 1: Change region to us-east-2 (where AMI exists)
Edit terraform/variables.tf:
variable "aws_region" {
  default = "us-east-2"  # ← Use this region
}

Option 2: Find correct AMI for your region
1. Go to: https://cloud-images.ubuntu.com/locator/ec2/
2. Search for: 22.04 LTS amd64 hvm:ebs-ssd
3. Find your region (e.g., us-west-2)
4. Copy the AMI ID (starts with ami-)
5. Edit terraform/variables.tf:
   variable "ami_id" {
     default = "ami-xxxxxxxxx"  # ← Your region's AMI
   }
```

---

### Error 12: "Error creating Security Group: InvalidGroup.Duplicate"

**Symptom:**
```
Error: Error creating Security Group: InvalidGroup.Duplicate: 
The security group 'jenkins-project-sg' already exists
```

**Cause:** Security group from previous run still exists

**Solution:**
```
Option 1: Delete via Terraform
cd terraform
terraform destroy -auto-approve

Option 2: Delete manually in AWS Console
1. AWS Console → EC2 → Security Groups
2. Find: jenkins-project-sg
3. Select it → Actions → Delete Security Group

Option 3: Change the name
Edit terraform/main.tf:
resource "aws_security_group" "builder_sg" {
  name = "jenkins-project-sg-v2"  # ← Add version number
  ...
}
```

---

### Error 13: "Error acquiring the state lock"

**Symptom:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Operation: OperationTypeApply
```

**Cause:** Another Terraform process is running (or crashed previously)

**Solution:**
```
Option 1: Wait and retry (if another job is genuinely running)
Wait 5-10 minutes, then run pipeline again

Option 2: Force unlock (if previous job crashed)
cd terraform
terraform force-unlock xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                       Use the ID from the error message

Then run pipeline again
```

---

### Error 14: "Error creating key pair: InvalidKeyPair.Duplicate"

**Symptom:**
```
Error: Error creating key pair: InvalidKeyPair.Duplicate: 
The keypair 'builder_key' already exists
```

**Cause:** Key pair from previous run still exists

**Solution:**
```
1. AWS Console → EC2 → Key Pairs
2. Find: builder_key
3. Select it → Actions → Delete
4. Run Terraform again

Note: This is normal if you run the pipeline multiple times.
Consider running 'terraform destroy' between tests.
```

---

## 🌐 Dashboard Access Issues

### Error 15: "Connection Refused" when accessing dashboard

**Symptom:**
```
Browser error: "Connection refused" or "Unable to connect"
URL: http://3.145.112.89:5001
```

**Cause:** Multiple possible causes

**Diagnosis Steps:**
```
1. Verify instance is running:
   AWS Console → EC2 → Instances
   Status should be: Running

2. Check Security Group:
   Select instance → Security tab
   Verify inbound rule exists:
   - Type: Custom TCP
   - Port: 5001
   - Source: 0.0.0.0/0

3. SSH into instance and check Docker:
   ssh -i builder_key.pem ubuntu@<public-ip>
   docker ps
   # Should show: flask-dashboard container running
```

**Solutions:**
```
If container not running:
docker logs flask-dashboard  # Check for errors
docker restart flask-dashboard

If security group missing rule:
AWS Console → EC2 → Security Groups → jenkins-project-sg
Add inbound rule: Custom TCP, Port 5001, Source 0.0.0.0/0

If instance stopped:
AWS Console → EC2 → Instances → Select instance
Actions → Instance State → Start
```

---

### Error 16: Dashboard shows "Metadata Service Unavailable"

**Symptom:**
Dashboard loads but shows:
```
Public IP Address: Metadata Service Unavailable (Check IMDSv2 settings)
```

**Cause:** Container can't reach AWS metadata service

**Solution:**
```
SSH into EC2 instance:
ssh -i builder_key.pem ubuntu@<public-ip>

Test IMDSv2:
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
echo $TOKEN
# Should show a long token string

curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
     http://169.254.169.254/latest/meta-data/public-ipv4
# Should show the instance's public IP

If token is empty:
Check instance metadata options:
AWS Console → EC2 → Instance → Actions → Instance Settings → 
Modify instance metadata options
Ensure: "IMDSv2" is set to "Required"

If still failing:
Check Docker container:
docker logs flask-dashboard
# Look for Python errors in metadata fetching
```

---

### Error 17: "ERR_ADDRESS_INVALID" in browser

**Symptom:**
```
Browser error: ERR_ADDRESS_INVALID
```

**Cause:** Malformed URL or missing http://

**Solution:**
```
Verify URL format:
✗ Wrong: 3.145.112.89:5001
✗ Wrong: https://3.145.112.89:5001  (no HTTPS)
✓ Correct: http://3.145.112.89:5001

Copy the exact URL from Terraform output:
cd terraform
terraform output web_dashboard_url
```

---

### Error 18: Dashboard is very slow to load

**Symptom:**
Dashboard takes 30+ seconds to load, or times out

**Cause:** Network latency or metadata service timeout

**Solution:**
```
SSH into instance:
ssh -i builder_key.pem ubuntu@<public-ip>

Check Docker container health:
docker stats flask-dashboard
# Check CPU and Memory usage

Check logs for timeout errors:
docker logs --tail 50 flask-dashboard

Restart container:
docker restart flask-dashboard

Check application from instance itself:
curl http://localhost:5001
# Should return HTML quickly
```

---

## 🔐 AWS Permission Errors

### Error 19: "AuthFailure: AWS was not able to validate the provided credentials"

**Symptom:**
```
Error: AuthFailure: AWS was not able to validate the provided access credentials
```

**Cause:** Wrong AWS credentials configured

**Solution:**
```
1. Verify credentials in Jenkins match AWS:
   Jenkins → Credentials → aws-access-key-id
   - Click "Update"
   - Check the Secret value matches your actual Access Key ID

2. Test credentials manually:
   aws configure
   # Enter the same credentials
   aws ec2 describe-instances --region us-east-2
   # Should work without error

3. If keys are old, create new ones:
   AWS Console → IAM → Users → Your User → Security Credentials
   Create new access key
   Update Jenkins credentials
```

---

### Error 20: "InvalidKeyPair.NotFound: The key pair 'builder_key' does not exist"

**Symptom:**
```
Error: InvalidKeyPair.NotFound: The key pair 'builder_key' does not exist
```

**Cause:** Key pair was deleted or Terraform state is out of sync

**Solution:**
```
Option 1: Let Terraform recreate it
terraform destroy -auto-approve
terraform apply -auto-approve

Option 2: Manually delete from AWS first
AWS Console → EC2 → Key Pairs
Delete 'builder_key' if it exists
Run pipeline again

Option 3: Use different key name
Edit terraform/variables.tf:
variable "key_name" {
  default = "builder_key_v2"  # ← Change name
}
```

---

## 🔍 General Debugging Tips

### Get More Information

**Jenkins Console Output:**
```
1. Click on build number (e.g., #3)
2. Click "Console Output"
3. Read from bottom up (most recent error is at bottom)
4. Look for ERROR, FAILED, or Exception
```

**AWS Console Logs:**
```
AWS Console → CloudWatch → Log Groups
Look for: /aws/ec2/<instance-id>
(If configured - not enabled by default in this project)
```

**Docker Container Logs:**
```bash
# SSH into EC2 instance
ssh -i builder_key.pem ubuntu@<public-ip>

# View logs
docker logs flask-dashboard

# Follow logs in real-time
docker logs -f flask-dashboard

# Last 50 lines only
docker logs --tail 50 flask-dashboard
```

**Terraform Debug Mode:**
```bash
# Run with debug output
TF_LOG=DEBUG terraform apply
```

---

### Test Components Individually

**Test 1: Docker Build Only**
```bash
cd app
docker build -t test-image .
# Should complete without errors
```

**Test 2: Docker Run Locally**
```bash
docker run -p 5001:5001 \
  -e INSTANCE_TYPE="test" \
  -e REGION="test" \
  -e VPC_ID="test" \
  -e SSH_KEY_PATH="test" \
  test-image

# Open browser: http://localhost:5001
# Should show dashboard (with test values)
```

**Test 3: Terraform Plan**
```bash
cd terraform
terraform plan
# Should show what will be created
# Should NOT show errors
```

---

### Check Resource Limits

**AWS Service Quotas:**
```
AWS Console → Service Quotas → Amazon EC2
Check:
- EC2 instances (should allow at least 1)
- Elastic IPs (should allow at least 1)
- Security Groups (should allow at least 1)
```

**Docker Disk Space:**
```bash
docker system df
# Shows space used by:
# - Images
# - Containers
# - Volumes
# - Build cache
```

---

## 📞 Still Stuck?

If none of these solutions work:

### Collect This Information:

1. **Exact error message** (copy entire error, not paraphrase)
2. **Jenkins console output** (last 50-100 lines)
3. **What stage failed** (Clone, Build, Push, or Deploy?)
4. **AWS region** you're using
5. **Terraform version**: `terraform --version`
6. **Docker version**: `docker --version`

### Things to Try:

```
1. Clean Workspace:
   Jenkins → Project → "Clean Workspace"
   Run again

2. Fresh Start:
   terraform destroy -auto-approve
   docker system prune -a -f
   Run pipeline again

3. Check AWS Service Health:
   https://status.aws.amazon.com/
   (Rare, but AWS services occasionally have outages)

4. Simplify:
   Try running stages manually one at a time
   cd app && docker build -t test .
   docker push test
   cd ../terraform && terraform apply
```

---

## ✅ Success Checklist

When everything works, you should see:

```
Jenkins Pipeline:
✓ All 5 stages completed (green checkmarks)
✓ Console shows: "Finished: SUCCESS"
✓ No error messages in console output
✓ Terraform outputs displayed

AWS Console:
✓ EC2 instance running (status: Running)
✓ Instance has public IP assigned
✓ Security group exists: jenkins-project-sg
✓ Key pair exists: builder_key

Dashboard:
✓ URL accessible: http://<ip>:5001
✓ Page loads quickly (< 5 seconds)
✓ All metadata fields show real values
✓ No "Metadata Service Unavailable" errors
✓ Pretty purple gradient background visible

Docker Hub:
✓ Image visible at: https://hub.docker.com/r/<username>/flask-aws-monitor
✓ Tag 'latest' exists
✓ Recent push timestamp
```

---

## 🎓 Prevention Tips

**Before Running Pipeline:**
- ✓ Verify all credentials in Jenkins
- ✓ Check AWS permissions are sufficient
- ✓ Ensure Docker daemon is running
- ✓ Confirm Terraform is installed
- ✓ Test with `terraform plan` first

**After Successful Run:**
- ✓ Document your configuration
- ✓ Save Terraform outputs
- ✓ Note the AMI ID for your region
- ✓ Remember to run `terraform destroy` when done testing

**Regular Maintenance:**
- Clean Docker images: `docker system prune`
- Rotate AWS keys every 90 days
- Keep Terraform updated
- Monitor AWS costs weekly

---

**Good luck! Remember: Most errors have simple solutions. Read error messages carefully!** 🚀