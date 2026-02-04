pipeline {
    agent any

    environment {
        // Must match the IDs in Jenkins Manage Credentials
        DOCKER_CREDS = credentials('dockerhub-credentials') 
        IMAGE_NAME   = "yaelitrovnik/flask-aws-monitor"
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
                            echo "--- Running Linting ---"
                            dir('app') {
                                // Ignore long lines (E501) common in HTML-in-Python
                                sh 'pip install flake8 && flake8 app.py --ignore=E501 || true'
                            }
                        }
                    }
                }
                stage('Security Scan') {
                    steps {
                        script {
                            echo "--- Running Security Scan ---"
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
                    echo "--- Building Image ---"
                    // Use 'app/' as the build context because the Dockerfile is inside it
                    sh "docker build -t ${IMAGE_NAME}:${env.BUILD_NUMBER} -t ${IMAGE_NAME}:latest app/"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "--- Pushing to Docker Hub ---"
                    sh "echo $DOCKER_CREDS_PASSWORD | docker login -u $DOCKER_CREDS_USR --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy Infrastructure (Terraform)') {
            environment {
                AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
                AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
            }
            steps {
                script {
                    echo "--- Starting Terraform Deployment ---"
                    dir('terraform') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                        // This prints the final URL in your Jenkins Console Output
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
                // Optional: Clean up workspace to save disk space
                cleanWs()
            }
        }
        success {
            echo "🚀 Deployment Successful! Check the URL in the logs above."
        }
        failure {
            echo "❌ Pipeline Failed. Check the 'Console Output' for details."
        }
    }
}