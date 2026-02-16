pipeline {
    agent any

    // New users just type their username in the Jenkins UI.
    parameters {
        string(name: 'DOCKER_USER', defaultValue: 'yaelitrovnik', description: 'Your Docker Hub Username')
    }

    environment {
        // We reference the parameter here so the rest of the script is dynamic
        IMAGE_NAME   = "${params.DOCKER_USER}/flask-aws-monitor"
        DOCKER_CREDS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Clone Repository') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Parallel Quality Checks') {
            parallel {
                stage('Linting') {
                    steps {
                        script {
                            dir('app') {
                                sh 'pip install flake8 && flake8 app.py --ignore=E501 || true'
                            }
                        }
                    }
                }
                stage('Security Scan') {
                    steps {
                        script {
                            dir('app') {
                                sh 'pip install bandit && bandit -r . || true'
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "--- Building Image for user: ${params.DOCKER_USER} ---"
                    sh "docker build -t ${IMAGE_NAME}:${env.BUILD_NUMBER} -t ${IMAGE_NAME}:latest app/"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // SECURE: No passwords here. Jenkins pulls them from the 'dockerhub-credentials' ID.
                    sh "echo \$DOCKER_CREDS_PSW | docker login -u \$DOCKER_CREDS_USR --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy Infrastructure (Terraform)') {
            environment {
                // SECURE: These are mapped to variables only for this stage's memory
                AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
                AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
            }
            steps {
                script {
                    dir('terraform') {
                        sh 'terraform init'
                        // DYNAMIC: Passing the Docker User parameter directly into Terraform
                        sh "terraform apply -auto-approve -var='docker_username=${params.DOCKER_USER}'"
                        sh 'terraform output web_dashboard_url'
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                sh "docker logout"
                cleanWs()
            }
        }
    }
}