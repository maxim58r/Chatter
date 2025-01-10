pipeline {
    agent { label 'chatter' }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'develop', description: 'Название ветки для сборки')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Пропустить этап тестирования')
        booleanParam(name: 'DEPLOY_TO_KUBERNETES', defaultValue: true, description: 'Выполнять деплой на Kubernetes')
        booleanParam(name: 'RUN_HEALTH_CHECK', defaultValue: true, description: 'Выполнять проверку состояния сервисов')
    }

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')    // ID Docker Hub Credentials (username + password)
        GITHUB_CRED      = credentials('github_ssh_key') // ID для GitHub Credentials
        KUBECONFIG       = "/var/lib/jenkins/.kube/config"
        SERVICES         = "authservice chatservice messagingservice notificationservice" // Список сервисов
    }

    stages {

        stage('Checkout') {
            steps {
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
            steps {
                sh """
                  echo "=== Setup Environment ==="
                  set -e
                  java -version
                  mvn --version
                  docker --version
                  helm version
                """
            }
        }

        stage('Build & Test') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                sh """
                  echo "=== Build & Test with Maven ==="
                  mvn clean package
                """
            }
        }

        stage('SpotBugs Analysis') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                sh "mvn spotbugs:spotbugs"
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
                    env.SERVICES.split().each { service ->
                        echo "=== Building Docker image for ${service} ==="
                        sh """
                          docker build -t ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ./services/${service}
                          docker push ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER}
                          docker tag ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ${DOCKER_HUB_CREDS_USR}/${service}:latest
                          docker push ${DOCKER_HUB_CREDS_USR}/${service}:latest
                        """
                    }
                }
            }
        }

        stage('Apply ConfigMap') {
            steps {
                script {
                    sh 'kubectl apply -f k8s/configmap/global-configmap.yaml'
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            when {
                expression { params.DEPLOY_TO_KUBERNETES }
            }
            steps {
                script {
                    env.SERVICES.split().each { service ->
                        echo "=== Deploying ${service} to Kubernetes with Helm ==="
                        sh """
                          helm upgrade --install ${service} ./k8s/${service}/helm \
                              --set image.repository=${DOCKER_HUB_CREDS_USR}/${service} \
                              --set image.tag=latest \
                        """
                    }
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.RUN_HEALTH_CHECK }
            }
            steps {
                script {
                    env.SERVICES.split().each { service ->
                        echo "=== Performing Health Check for ${service} ==="
                        sh """
                          curl --fail --max-time 10 http://${service}.local/actuator/health || {
                              echo "Health check failed for ${service}";
                              exit 1;
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
        cleanup {
            sh "docker logout"
        }
    }
}
