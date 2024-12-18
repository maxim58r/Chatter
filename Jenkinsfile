pipeline {
    agent { label 'chatter' }  // Использование узла Jenkins

    environment {
        DOCKER_HUB_USER = credentials('docker-hub-username')  // ID Docker Hub Credentials
        DOCKER_HUB_PASS = credentials('docker-hub-password')
        GITHUB_USER = credentials('github-credentials')  // ID для GitHub Credentials
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
                echo "Setting up Java, Maven, and Docker"
                java -version
                mvn --version
                docker --version
                '''
            }
        }

        stage('Run Tests and Build') {
            steps {
                sh '''
                echo "Running Maven Tests"
                mvn clean test

                echo "Building Maven Artifacts"
                mvn clean package
                '''
            }
        }

        stage('Run Checkstyle and SpotBugs') {
            steps {
                sh '''
                echo "Running Checkstyle..."
                mvn checkstyle:check

                echo "Running SpotBugs..."
                mvn spotbugs:check
                '''
            }
        }

        stage('CodeQL Analysis') {
            steps {
                echo 'Running CodeQL Analysis...'
                sh '''
                mkdir -p codeql
                wget https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
                unzip -o codeql-linux64.zip -d codeql
                ./codeql/codeql/codeql database create --language=java codeql-db
                ./codeql/codeql/codeql database analyze codeql-db --format=sarif-latest --output=codeql-results.sarif
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    def services = ['auth-service', 'chat-service', 'messaging-service', 'notification-service']
                    services.each { service ->
                        sh """
                        echo "Building Docker image for ${service}..."
                        docker build -t ${DOCKER_HUB_USER}/${service}:${env.BUILD_NUMBER} ./services/${service}
                        docker tag ${DOCKER_HUB_USER}/${service}:${env.BUILD_NUMBER} ${DOCKER_HUB_USER}/${service}:latest
                        """
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                script {
                    sh "echo ${DOCKER_HUB_PASS} | docker login -u ${DOCKER_HUB_USER} --password-stdin"
                    def services = ['auth-service', 'chat-service', 'messaging-service', 'notification-service']
                    services.each { service ->
                        sh """
                        echo "Pushing Docker image for ${service}..."
                        docker push ${DOCKER_HUB_USER}/${service}:${env.BUILD_NUMBER}
                        docker push ${DOCKER_HUB_USER}/${service}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'  // Деплой в production только с ветки main
            }
            steps {
                sh '''
                echo "Applying Kubernetes Manifests..."
                kubectl apply -f k8s/

                echo "Checking Rollout Status..."
                kubectl rollout status deployment/auth-service
                kubectl rollout status deployment/chat-service
                kubectl rollout status deployment/messaging-service
                kubectl rollout status deployment/notification-service
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                echo "Performing Health Check..."
                curl --fail http://localhost:8080/actuator/health || exit 1
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                echo 'Archiving Checkstyle, SpotBugs, and CodeQL reports...'
                archiveArtifacts artifacts: '**/target/checkstyle-result.xml, **/target/spotbugsXml.xml, codeql-results.sarif', fingerprint: true
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
