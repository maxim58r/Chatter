pipeline {
    agent { label 'chatter' }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'develop', description: 'Название ветки для сборки')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Пропустить этап тестирования')
        booleanParam(name: 'DEPLOY_TO_KUBERNETES', defaultValue: true, description: 'Выполнять деплой на Kubernetes')
        booleanParam(name: 'RUN_HEALTH_CHECK', defaultValue: true, description: 'Выполнять проверку состояния сервисов')
    }

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')
        GITHUB_CRED      = credentials('github_ssh_key')
        KUBECONFIG       = "/var/lib/jenkins/.kube/config"
        SERVICES         = "authservice chatservice messagingservice notificationservice"
        DOCKER_BUILDKIT  = '1' // Enable BuildKit
    }

    stages {
	
		stage('Deploy PostgreSQL') {
            steps {
                script {
                    sh '''
                    helm repo add bitnami https://charts.bitnami.com/bitnami
                    helm repo update
                    helm install postgres bitnami/postgresql \
                      --set persistence.enabled=true \
                      --set persistence.size=8Gi \
                      --set auth.username=postgres,auth.password=postgres_password,auth.database=your_database_name
                    '''
                }
            }
        }

        stage('Apply Liquibase Changes for AuthService') {
                    steps {
                        dir('services/authservice') {
                            sh '''
                    mvn liquibase:update \
                      -Dliquibase.url=jdbc:postgresql://127.0.0.1:32172/postgres_auth \
                      -Dliquibase.username=postgres \
                      -Dliquibase.password=postgres
                    '''
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    echo "Checking out branch ${params.BRANCH_NAME}..."
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${params.BRANCH_NAME}"]],
                        userRemoteConfigs: [[
                            url: 'git@github.com:maxim58r/Chatter.git',
                            credentialsId: 'github_ssh_key'
                        ]],
                        extensions: [
                            [$class: 'SubmoduleOption', recursiveSubmodules: true, trackingSubmodules: true]
                        ]
                    ])
                    sh """
                      echo "Updating submodules to branch ${params.BRANCH_NAME}..."
                      git submodule foreach --recursive 'git checkout ${params.BRANCH_NAME} || true'
                      git submodule foreach --recursive 'git pull origin ${params.BRANCH_NAME} || true'
                    """
                }
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

        stage('Prepare Buildx') {
            steps {
                sh """
                  docker buildx create --name mybuilder --driver docker-container --use || true
                  docker buildx inspect --bootstrap
                """
            }
        }

        stage('Build & Push Docker Images with Buildx') {
            steps {
                script {
                    env.SERVICES.split().each { service ->
                        echo "=== Building Docker image for ${service} ==="
                        sh """
                          docker buildx build \
                              --platform linux/amd64,linux/arm64 \
                              -t ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} \
                              -t ${DOCKER_HUB_CREDS_USR}/${service}:latest \
                              --push ./services/${service}
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
                              --set image.tag=latest
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
                      echo "=== Waiting for ${service} Deployment to be ready ==="
                      sh """
                        kubectl rollout status deployment/${service} --namespace=default --timeout=60s
                      """
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
