pipeline {
    agent { label 'chatter' }

    environment {
        DOCKER_HUB_CREDS = credentials('docker_hub')
        GITHUB_CRED      = credentials('github_ssh_key')
        KUBECONFIG       = "/var/lib/jenkins/.kube/config"
        SERVICES         = "authservice chatservice messagingservice notificationservice"
    }

    options {
        timestamps() // Добавляем временные метки к логам
        timeout(time: 60, unit: 'MINUTES') // Общий таймаут пайплайна
    }

    stages {

        stage('Checkout') {
            steps {
                script {
                    checkout scm: [
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[
                            url: 'git@github.com:maxim58r/Chatter.git',
                            credentialsId: 'github_ssh_key'
                        ]],
                        extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true]]
                    ]
                }
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
                  mvn clean package
                '''
            }
        }

        stage('SpotBugs Analysis') {
            steps {
                sh "mvn spotbugs:spotbugs"
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    sh '''
                      echo "=== Docker Login ==="
                      echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin
                    '''
                }
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                script {
                    env.SERVICES.split().each { service ->
                        echo "=== Building Docker image for ${service} ==="
                        sh """
                            docker build -t ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ./services/${service} || {
                                echo "Error building image for ${service}";
                                exit 1;
                            }
                            docker push ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} || {
                                echo "Error pushing image for ${service}";
                                exit 1;
                            }
                            docker tag ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ${DOCKER_HUB_CREDS_USR}/${service}:latest
                            docker push ${DOCKER_HUB_CREDS_USR}/${service}:latest || {
                                echo "Error tagging/pushing 'latest' for ${service}";
                                exit 1;
                            }
                        """
                    }
                }
            }
        }

        stage('Verify Kubernetes Connection') {
            steps {
                sh '''
                  echo "=== Verifying Kubernetes Connection ==="
                  kubectl get nodes
                  kubectl config get-contexts
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    env.SERVICES.split().each { service ->
                        sh '''
                          echo "=== Deploying ${service} to Kubernetes ==="
                          kubectl apply -f k8s/${service}/deployment.yaml
                          kubectl apply -f k8s/${service}/service.yaml
                          kubectl apply -f k8s/${service}/ingress.yaml

                          echo "=== Checking Rollout Status for ${service} ==="
                          kubectl rollout status deployment/${service} --timeout=60s
                        '''
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    env.SERVICES.split().each { service ->
                        sh '''
                          echo "=== Performing Health Check for ${service} ==="
                          curl --fail http://${service}.local:31547/actuator/health || {
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
