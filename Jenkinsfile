pipeline {
    agent { label 'chatter' } // Используем Jenkins-агент "chatter"

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')    // ID Docker Hub Credentials (username + password)
        GITHUB_CRED      = credentials('github_jenkins') // ID для GitHub Credentials
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }

    stages {

        stage('Checkout Code') {
            steps {
//                 checkout scm

                git branch: 'main',
                    credentialsId: 'github_jenkins',
                    url: 'https://github.com/maxim58r/Chatter.git'

            }
        }

        stage('Setup Environment') {
            steps {
                sh """
                  echo "=== Setup Environment ==="
                  set -e
                  java -version
                  mvn --version
                  docker --version
                """
            }
        }

        stage('Verify Maven Settings') {
            steps {
                sh """
                if [ ! -f /home/jenkins-agent/.m2/settings.xml ]; then
                  echo "Error: settings.xml not found!"
                  exit 1
                fi
                """
            }
        }

        stage('Build & Test') {
            steps {
                sh """
                  echo "=== Build & Test with Maven ==="
                  mvn clean package -s /home/jenkins-agent/.m2/settings.xml
                """
            }
        }

        stage('SpotBugs Analysis') {
            steps {
                sh "mvn spotbugs:spotbugs"
                // Или spotbugs:check
            }
        }


        stage('Login to Docker Hub') {
            steps {
                sh """
                  echo "=== Docker Login ==="
                  echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin
                """
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                script {
                    def services = ['authservice', 'chatservice', 'messagingservice', 'notificationservice']
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

        stage('Verify Kubernetes Connection') {
            steps {
                script {
                    sh '''
                    echo "Using KUBECONFIG: $KUBECONFIG"
                    kubectl get nodes
                    kubectl config get-context
                    '''
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
                  for service in $(ls k8s); do
                      kubectl apply -f k8s/$service/deployment.yaml
                      kubectl apply -f k8s/$service/service.yaml
                  done

                  echo "=== Checking Rollout Status ==="
                  kubectl rollout status deployment/authservice
                  kubectl rollout status deployment/chatservice
                  kubectl rollout status deployment/messagingservice
                  kubectl rollout status deployment/notificationservice
                '''
            }
        }

        stage('Health Check') {
            steps {
                script {
                    def services = ['authservice', 'chatservice', 'messagingservice', 'notificationservice']
                    echo "Services to check: ${services.join(', ')}"
                    services.each { service ->
                        sh """
                          echo "=== Performing Health Check for ${service} ==="
                          curl --fail http://${service}.default.svc.cluster.local:8080/actuator/health || {
                              echo "Health check failed for ${service}"
                              exit 1
                          }
                        """
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
