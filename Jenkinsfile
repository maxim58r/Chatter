pipeline {
    agent any
    tools {
        git 'Default Git'
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/maxim58r/Chatter.git'
            }
        }
    }
}



// pipeline {
//     agent { label 'chatter' }  // Использование узла Jenkins
//
//     environment {
//         DOCKER_HUB_CREDS = credentials('docker_hub')  // ID Docker Hub Credentials
//         GITHUB_USER = credentials('github-cred')  // ID для GitHub Credentials
//     }
//
//     stages {
//         stage('Clean Workspace') {
//             steps {
//                 deleteDir()
//             }
//         }
//
//         stage('Checkout Code') {
//             steps {
//                 checkout scm
//                 sh '''
//                 git submodule init
//                 git submodule update
//                 '''
//             }
//         }
//
//         stage('Setup Environment') {
//             steps {
//                 sh '''
//                 echo "Setting up Java, Maven, and Docker"
//                 java -version
//                 mvn --version
//                 docker --version
//                 '''
//             }
//         }
//
//         stage('Run Tests') {
//             steps {
//                 sh '''
//                 echo "Running Maven Tests"
//                 mvn -s /home/jenkins-agent/.m2/settings.xml test
//                 '''
//             }
//         }
//
// //          stage('Build Maven Project') {
// //                     steps {
// //                         withCredentials([usernamePassword(credentialsId: 'github-cred',
// //                                                          usernameVariable: 'GITHUB_USER',
// //                                                          passwordVariable: 'GITHUB_TOKEN')]) {
// //                             sh '''
// //                                 mvn clean package \
// //                                     -Dgithub.user=$GITHUB_USER \
// //                                     -Dgithub.token=$GITHUB_TOKEN
// //                             '''
// //                         }
// //                     }
// //          }
//
//         stage('Build Artifacts') {
//             steps {
//                 sh '''
//                 echo "Building Maven Artifacts"
//                 mvn -s /home/jenkins-agent/.m2/settings.xml package
//                 '''
//             }
//         }
//
// //         stage('Run Checkstyle and SpotBugs') {
// //             steps {
// //                 sh '''
// //                 echo "Running Checkstyle..."
// //                 mvn checkstyle:check
// //
// //                 echo "Running SpotBugs..."
// //                 mvn spotbugs:check
// //                 '''
// //             }
// //         }
//
//
//         stage('CodeQL Analysis') {
//             steps {
//                 echo 'Running CodeQL Analysis...'
//                 sh '''
//                 mkdir -p codeql
//                 wget https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
//                 unzip -o codeql-linux64.zip -d codeql
//                 ./codeql/codeql/codeql database create --language=java codeql-db --overwrite
//                 ./codeql/codeql/codeql database analyze codeql-db --format=sarif-latest --output=codeql-results.sarif
//                 '''
//             }
//         }
//
//
//         stage('Login to Docker Hub') {
//             steps {
//                 sh '''
//                 echo $DOCKER_HUB_CREDS_PSW | docker login -u $DOCKER_HUB_CREDS_USR --password-stdin
//                 '''
//             }
//         }
//
//         stage('Build Docker Images') {
//             steps {
//                 script {
//                     def services = ['auth-service', 'chat-service', 'messaging-service', 'notification-service']
//                     services.each { service ->
//                         sh """
//                         docker build -t ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ./services/${service}
//                         docker push ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER}
//                         docker tag ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER} ${DOCKER_HUB_CREDS_USR}/${service}:latest
//                         docker push ${DOCKER_HUB_CREDS_USR}/${service}:latest
//                         """
//                     }
//                 }
//             }
//         }
//
//         stage('Push Docker Images') {
//             steps {
//                 script {
//                     sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
//                     def services = ['auth-service', 'chat-service', 'messaging-service', 'notification-service']
//                     services.each { service ->
//                         sh """
//                         echo "Pushing Docker image for ${service}..."
//                         docker push ${DOCKER_HUB_CREDS_USR}/${service}:${env.BUILD_NUMBER}
//                         docker push ${DOCKER_HUB_CREDS_USR}/${service}:latest
//                         """
//                     }
//                 }
//             }
//         }
//
//         stage('Deploy to Kubernetes') {
//             when {
//                 branch 'main'  // Деплой в production только с ветки main
//             }
//             steps {
//                 sh '''
//                 echo "Applying Kubernetes Manifests..."
//                 kubectl apply -f k8s/
//
//                 echo "Checking Rollout Status..."
//                 kubectl rollout status deployment/auth-service
//                 kubectl rollout status deployment/chat-service
//                 kubectl rollout status deployment/messaging-service
//                 kubectl rollout status deployment/notification-service
//                 '''
//             }
//         }
//
//         stage('Health Check') {
//             steps {
//                 sh '''
//                 echo "Performing Health Check..."
//                 curl --fail http://localhost:8080/actuator/health || exit 1
//                 '''
//             }
//         }
//
//         stage('Archive Reports') {
//             steps {
//                 echo 'Archiving Checkstyle, SpotBugs, and CodeQL reports...'
//                 archiveArtifacts artifacts: '**/target/checkstyle-result.xml, **/target/spotbugsXml.xml, codeql-results.sarif', fingerprint: true
//             }
//         }
//     }
//
//     post {
//         success {
//             echo "✅ Build and deployment successful!"
//         }
//         failure {
//             echo "❌ Build or deployment failed!"
//         }
//     }
// }
