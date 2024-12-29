pipeline {
    agent { label 'chatter' } // Используем Jenkins-агент "chatter"

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')    // ID Docker Hub Credentials (username + password)
        GITHUB_CRED      = credentials('github_ssh_key') // ID для GitHub Credentials
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'git@github.com:maxim58r/Chatter.git',
                        credentialsId: 'github_ssh_key'  // ID SSH Credentials
                    ]],
                    extensions: [
                        [$class: 'SubmoduleOption', recursiveSubmodules: true]
                    ]
                ])
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
                  mvn clean package
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
                    kubectl config get-contexts
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'echo "=== Deploy to Kubernetes ==="'

                    def services = ['authservice', 'chatservice', 'messagingservice', 'notificationservice']
                    services.each { s ->
                        sh """
                          kubectl apply -f k8s/${s}/deployment.yaml
                          kubectl apply -f k8s/${s}/service.yaml
                          kubectl apply -f k8s/${s}/ingress.yaml
                        """
                    }

                    sh '''
                      echo "=== Checking Rollout Status ==="
                      kubectl rollout status deployment/authservice
                      kubectl rollout status deployment/chatservice
                      kubectl rollout status deployment/messagingservice
                      kubectl rollout status deployment/notificationservice
                    '''
                }
            }
        }


        stage('Health Check') {
            steps {
                script {
                    def services = ['authservice', 'chatservice', 'messagingservice', 'notificationservice']
                    services.each { service ->
                        sh """
                          echo "=== Performing Health Check for ${service} ==="
                          curl --fail http://${service}.local/actuator/health || {
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
