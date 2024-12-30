pipeline {
    agent none

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Ветка для сборки')
        choice(name: 'STAGES_TO_RUN', choices: 'All\nBuild\nTest\nDeploy\nHealthCheck', description: 'Выберите этапы для запуска')
    }

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')    // ID Docker Hub Credentials (username + password)
        GITHUB_CRED      = credentials('github_ssh_key') // ID для GitHub Credentials
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }

    stages {

        stage('Checkout') {
            agent { label 'chatter' }
            steps {
                echo "=== Checkout branch: ${params.BRANCH_NAME} ==="
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.BRANCH_NAME}"]],
                    userRemoteConfigs: [[
                        url: 'git@github.com:maxim58r/Chatter.git',
                        credentialsId: 'github_ssh_key'
                    ]],
                    extensions: [
                        [$class: 'SubmoduleOption', recursiveSubmodules: true]
                    ]
                ])
            }
        }

        stage('Setup Environment') {
            agent { label 'chatter' }
            when {
                expression { params.STAGES_TO_RUN == 'All' || params.STAGES_TO_RUN == 'Setup' }
            }
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

        stage('Build & Test') {
            agent { label 'chatter' }
            when {
                expression { params.STAGES_TO_RUN == 'All' || params.STAGES_TO_RUN == 'Build' }
            }
            steps {
                sh """
                  echo "=== Build & Test with Maven ==="
                  mvn clean package
                """
            }
        }

        stage('Deploy to Kubernetes') {
            agent { label 'chatter' }
            when {
                expression { params.STAGES_TO_RUN == 'All' || params.STAGES_TO_RUN == 'Deploy' }
            }
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

                    sh """
                      echo "=== Checking Rollout Status ==="
                      kubectl rollout status deployment/authservice
                      kubectl rollout status deployment/chatservice
                      kubectl rollout status deployment/messagingservice
                      kubectl rollout status deployment/notificationservice
                    """
                }
            }
        }

        stage('Health Check') {
            agent { label 'chatter' }
            when {
                expression { params.STAGES_TO_RUN == 'All' || params.STAGES_TO_RUN == 'HealthCheck' }
            }
            steps {
                script {
                    def services = ['authservice', 'chatservice', 'messagingservice', 'notificationservice']
                    services.each { service ->
                        sh """
                          echo "=== Performing Health Check for ${service} ==="
                          curl --fail http://${service}.local:31547/actuator/health || {
                              echo "Health check failed for ${service}"
                              exit 1
                          }
                        """
                    }
                }
            }
        }

        stage('Archive Reports') {
            agent { label 'chatter' }
            when {
                expression { params.STAGES_TO_RUN == 'All' || params.STAGES_TO_RUN == 'Archive' }
            }
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

