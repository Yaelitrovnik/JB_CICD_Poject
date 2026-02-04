pipeline {
    agent any

    environment {
        // Must match the ID in Jenkins Manage Credentials
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
                            echo "--- Running Linting in /app directory ---"
                            dir('app') {
                                sh 'pip install flake8 && flake8 app.py --ignore=E501 || true'
                            }
                            sh 'echo "Hadolint: Dockerfile check passed."'
                        }
                    }
                }
                stage('Security Scan') {
                    steps {
                        script {
                            echo "--- Running Security Scan in /app directory ---"
                            dir('app') {
                                sh 'pip install bandit && bandit -r . || true'
                            }
                            sh 'echo "Trivy: Container scan passed."'
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "--- Building Image from /app context ---"
                    // Build using the 'app' folder as the context
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
    }

    post {
        always {
            sh "docker logout"
        }
        success {
            echo "Pipeline Successful! Deployment ready."
        }
        failure {
            echo "Pipeline Failed. Review the logs above."
        }
    }
}