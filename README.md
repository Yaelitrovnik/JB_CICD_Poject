# ☁️ Automated AWS EC2 Monitoring Dashboard
### CI/CD Pipeline with Jenkins, Docker, and Terraform

This project demonstrates a fully automated DevOps lifecycle. It provisions AWS infrastructure using **Terraform**, builds a containerized **Flask** application, and orchestrates the entire process via a **Jenkins** pipeline.

---

## 🏗️ 1. How the Process Works (The Flow)

1.  **Code Push**: Developer pushes code to GitHub.
2.  **Webhook**: GitHub triggers a Jenkins build.
3.  **Continuous Integration (CI)**:
    * **Linting**: Flake8 checks Python code for errors.
    * **Security**: Bandit scans for vulnerabilities.
    * **Docker Build**: Jenkins builds an image of the Flask app.
    * **Docker Push**: Image is pushed to Docker Hub with a unique version tag.
4.  **Continuous Deployment (CD)**:
    * **Terraform**: Provisions an EC2 instance, Security Groups, and SSH Keys.
    * **Dynamic Injection**: Jenkins passes the Docker username into Terraform.
    * **Bootstrap**: The EC2 instance uses `user_data` to install Docker and pull the latest image.
5.  **Live Dashboard**: The app becomes accessible at `http://<EC2_IP>:5001`.

---

## 🛠️ 2. Prerequisites

Before you start, you must have:
* An **AWS Account** with an IAM user (Access/Secret keys).
* A **Docker Hub Account**.
* **Jenkins** installed with the following plugins:
    * Docker Pipeline
    * Terraform Plugin
    * GitHub Integration

---

## 🚀 3. Setup Guide (Step-by-Step)

### Step 1: Jenkins Credentials
In Jenkins, go to **Manage Jenkins > Credentials** and add these three secrets:
| ID | Type | Description |
| :--- | :--- | :--- |
| `dockerhub-credentials` | Username/Password | Your Docker Hub login |
| `aws-access-key-id` | Secret Text | Your AWS Access Key |
| `aws-secret-access-key` | Secret Text | Your AWS Secret Key |

### Step 2: Configure Terraform Tool
1.  Go to **Manage Jenkins > Global Tool Configuration**.
2.  Add **Terraform**. Name it `terraform` and set it to install automatically.

### Step 3: Connect GitHub Webhook

1.  In your GitHub Repo: **Settings > Webhooks > Add Webhook**.
2.  Payload URL: `http://<YOUR_JENKINS_IP>:8080/github-webhook/`.
3.  Content type: `application/json`.

### Step 4: Run the Pipeline
1.  Create a new **Pipeline** job in Jenkins.
2.  Set "Definition" to **Pipeline script from SCM**.
3.  Select **Git** and enter your repo URL.
4.  **Build Now** once (this initializes the parameters).
5.  From now on, use **Build with Parameters** and enter your Docker username.

---

## 📂 4. Project Structure

```text
.
├── Jenkinsfile             # Automation Pipeline
├── app/                    # Flask Application & Dockerfile
│   ├── app.py             
│   ├── Dockerfile        
│   └── requirements.txt                  
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # EC2 & Security Resources
│   ├── variables.tf        # Configuration Inputs
│   └── user_data.sh        # EC2 Bootstrap Template
└── WEBHOOK_GUIDE.md        # Detailed Webhook troubleshooting
```
---

## 🖥️ 5. The Dashboard
The deployed Flask app securely fetches real-time metadata using AWS IMDSv2, displaying:

 - Instance Public IP

 - VPC & Subnet ID

 - Instance Type

 - Region & Availability Zone

---

## 🧹 6. Cleanup
To avoid AWS costs, you can run the Terraform Destroy command: 
``` bash
terraform destroy -var='docker_username=your_user' 
```
---