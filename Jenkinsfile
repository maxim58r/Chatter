pipeline {
    agent { label 'chatter' }  // Используем Jenkins-агент "chatter"

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')    // ID Docker Hub Credentials (username + password)
        GITHUB_CRED      = credentials('github_jenkins') // ID для GitHub Credentials
    }

    stages {

        stage('Checkout Code') {
            // Если в настройках job включена опция "Skip default checkout",
            // тогда нам нужен явный checkout scm
            // Если же Jenkins автоматически делает checkout, этот stage может быть опционален.
            steps {
                // Простейший вариант:
                checkout scm
            }
        }

//         stage('SonarQube Analysis') {
//             environment {
//                 SONAR_TOKEN = credentials('sonarqube-token')
//             }
//             steps {
//                 script {
//                     withSonarQubeEnv('SonarQube') {
//                         sh 'mvn sonar:sonar -Dsonar.projectKey=my-project'
//                     }
//                 }
//             }
//         }

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
//                 // Здесь поднимаем GitHub credentials, если нужно для приватного доступа (например, GitHub Packages)
//                 withCredentials([
//                     usernamePassword(
//                         credentialsId: 'github_jenkins',
//                         usernameVariable: 'GITHUB_USER',
//                         passwordVariable: 'GITHUB_TOKEN'
//                     )
//                 ]) {
                    sh '''
                      echo "=== Build & Test with Maven ==="
                      mvn clean package -s /home/jenkins-agent/.m2/settings.xml
                    '''
//                 }
            }
        }

//         stage('CodeQL Analysis') {
//             steps {
//                 script {
//                     withCodeQL(codeql: 'CodeQL 2.5.5') {
//                         sh '''
//                           echo "=== Running CodeQL Analysis ==="
//                           codeql database create --language=java codeql-db --overwrite --command "mvn clean package"
//                           codeql database analyze codeql-db --format=sarif-latest --output=codeql-results.sarif
//                         '''
//                     }
//                 }
//             }
//         }

        stage('CodeQL Analysis') {
            steps {
                script {
                    def codeqlPath = tool name: 'CodeQL', type: 'CodeQLCLI'
                    sh """
                        ${codeqlPath}/codeql database create --language=java codeql-db --overwrite --command "mvn clean package"
                        ${codeqlPath}/codeql database analyze codeql-db --format=sarif-latest --output=codeql-results.sarif
                    """
                }
            }
        }


        stage('Login to Docker Hub') {
            steps {
                // Один раз логинимся перед сборкой + пушем Docker-образов
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
                    // Собираем и пушим образы
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
                branch 'main'  // Деплой только с ветки main
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
                sh '''
                  echo "=== Performing Health Check ==="
                  curl --fail http://localhost:8080/actuator/health || exit 1
                '''
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
