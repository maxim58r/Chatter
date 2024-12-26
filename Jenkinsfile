pipeline {
    agent { label 'chatter' } // Используем Jenkins-агент "chatter"

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')    // ID Docker Hub Credentials (username + password)
        GITHUB_CRED      = credentials('github_jenkins') // ID для GitHub Credentials
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Setup Environment') {
            steps {
                sh '''
                  echo "=== Setup Environment ==="
                  set -e
                  java -version
                  mvn --version
                  docker --version
                '''
            }
        }

        stage('Verify Maven Settings') {
            steps {
                sh '''
                if [ ! -f /home/jenkins-agent/.m2/settings.xml ]; then
                  echo "Error: settings.xml not found!"
                  exit 1
                fi
                '''
            }
        }

        stage('Build & Test') {
            steps {
                sh '''
                  echo "=== Build & Test with Maven ==="
                  mvn clean package -s /home/jenkins-agent/.m2/settings.xml
                '''
            }
        }

        stage('Login to Docker Hub') {
            steps {
                sh '''
                  echo "=== Docker Login ==="
                  echo $DOCKER_HUB_CREDS_PSW | docker login -u $DOCKER_HUB_CREDS_USR --password-stdin
                '''
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                script {
                    def services = ['auth-service', 'chat-service', 'messaging-service', 'notification-service']
                    services.each { service ->
                        sh """
                          echo "=== Building Docker image for ${service} ==="
                          docker build -t ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ./services/${service}

                          echo "=== Pushing Docker image for ${service} ==="
                          docker push ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER}

                          echo "=== Tagging 'latest' for ${service} ==="
                          docker tag ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ${DOCKER_HUB_CREDS_USR}/${service}:latest
                          docker push ${DOCKER_HUB_CREDS_USR}/${service}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main' // Деплой только с ветки main
            }
            steps {
                sh '''
                  echo "=== Deploy to Kubernetes ==="
                  kubectl apply -f k8s/

                  echo "=== Checking Rollout Status ==="
                  kubectl rollout status deployment/auth-service
                  kubectl rollout status deployment/chat-service
                  kubectl rollout status deployment/messaging-service
                  kubectl rollout status deployment/notification-service
                '''
            }
        }

        stage('Health Check') {
            steps {
                script {
                    def services = ['auth-service', 'chat-service', 'messaging-service', 'notification-service']
                    services.each { service ->
                        sh '''
                          echo "=== Performing Health Check for ${service} ==="
                          curl --fail http://${service}.default.svc.cluster.local:8080/actuator/health || {
                              echo "Health check failed for ${service}"
                              exit 1
                          }
                        '''
                    }
                }
            }
        }

        stage('Archive Reports') {
            steps {
                echo '=== Archiving reports (SpotBugs, CodeQL) ==='
                archiveArtifacts artifacts: '**/target/spotbugsXml.xml, codeql-results.sarif', fingerprint: true
            }
        }
    }

    post {
        success {
            echo "✅ Build and deployment successful!"
        }
        failure {
            echo "❌ Build or deployment failed!"
        }
    }
}
