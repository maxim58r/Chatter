pipeline {
	agent { label 'chatter' }

    parameters {
		string(name: 'BRANCH_NAME', defaultValue: 'develop', description: 'Название ветки для сборки')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Пропустить этап тестирования')
    }

    environment {
		DOCKER_HUB_CREDS = credentials('docker_hub')
        GITHUB_CRED = credentials('github_ssh_key')
        SERVICES = "authservice chatservice messagingservice notificationservice"
        DOCKER_BUILDKIT = '1'
        DOCKER_CLIENT_TIMEOUT = '600'
        COMPOSE_HTTP_TIMEOUT = '600'
    }

    stages {

		stage('Validate Branch') {
			steps {
				script {
					// Разрешаем сборку только из develop или main
                    if (params.BRANCH_NAME != 'develop' && params.BRANCH_NAME != 'main') {
						error("Branch name must be 'develop' or 'main' only!")
                    }
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
                            // Важно: trackingSubmodules = true, recursiveSubmodules = true
                            [$class: 'SubmoduleOption', recursiveSubmodules: true, trackingSubmodules: true]
                        ]
                    ])
                }
            }
        }

        stage('Update Submodules') {
			steps {
				sh """
                  echo "=== Updating git submodules to the latest commit in their tracked branches ==="
                  git submodule sync --recursive
                  # переключение на ветку, прописанную в .gitmodules (или дефолтно) + мердж последних изменений
                  git submodule update --init --recursive --remote --merge
                """
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

        stage('Login to Docker Hub') {
			steps {
				withCredentials([usernamePassword(credentialsId: 'docker_hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
					sh '''
                      echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Prepare Buildx') {
            steps {
                sh """
                    echo "=== Using default buildx builder ==="
                    docker buildx use default
                    docker buildx inspect default --bootstrap
                """
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                script {
                   env.SERVICES.split().each { srv ->
                       try {
                           echo "=== Building Docker image for ${srv} ==="
                           sh """
                             docker buildx build \
                               --platform linux/amd64 \
                               --build-arg BUILDKIT_STEP_LOG_MAX_SIZE=104857600 \
                               --build-arg BUILDKIT_STEP_LOG_MAX_RETRIES=10 \
                               -t ${DOCKER_HUB_CREDS_USR}/${srv}:${env.BUILD_NUMBER} \
                               -t ${DOCKER_HUB_CREDS_USR}/${srv}:latest \
                               --push ./services/${srv}
                           """
                       } catch (Exception e) {
                           echo "Error building service '${srv}': ${e.message}"
                           currentBuild.result = 'FAILURE'
                           error("Build failed for service: ${srv}")
                       }
                   }
                }
            }
        }
    }

    post {
		success {
			echo "✅ Build successful!"
            script {
				writeFile file: 'successful-build-id.txt', text: "${env.BUILD_NUMBER}"
                archiveArtifacts artifacts: 'successful-build-id.txt', fingerprint: true
            }
        }
        failure {
			echo "❌ Build failed!"
            script {
				archiveArtifacts artifacts: '**/target/*.log', allowEmptyArchive: true
                sh 'docker logs $(docker ps -lq) || true'
            }
        }
        cleanup {
			sh """
              echo "=== Cleanup ==="
              docker logout
              if docker buildx ls | grep -q mybuilder; then
                  echo "Removing Docker Buildx builder 'mybuilder'..."
                  docker buildx rm mybuilder
              else
                  echo "No builder 'mybuilder' found, skipping removal."
              fi
            """
        }
    }
}


pipeline {
	agent { label 'chatter' }

    parameters {
		booleanParam(name: 'DEPLOY_TO_KUBERNETES', defaultValue: true, description: 'Выполнять деплой на Kubernetes')
        booleanParam(name: 'RUN_HEALTH_CHECK', defaultValue: true, description: 'Выполнять проверку состояния сервисов')
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Тег Docker-образов для деплоя')
        string(name: 'BUILD_ID', defaultValue: '', description: 'ID успешной сборки для деплоя')
    }

    environment {
		DOCKER_HUB_CREDS = credentials('docker_hub')
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
        SERVICES = "authservice chatservice messagingservice notificationservice"
    }

    stages {

		stage('Fetch Build Info') {
			steps {
				script {
					if (params.BUILD_ID) {
						// Если BUILD_ID указан, читаем файл с билдом и устанавливаем IMAGE_TAG
						copyArtifacts(
							projectName: 'chatter-multimodule-build-pipeline',
							selector: [
								$class: 'SpecificBuildSelector',
								buildNumber: params.BUILD_ID
							],
							filter: 'successful-build-id.txt'
						)
						def buildId = readFile('successful-build-id.txt').trim()
						echo "Using Build ID: ${buildId}"
						env.IMAGE_TAG = buildId
					} else {
						// Если BUILD_ID не указан, оставляем пользовательский IMAGE_TAG
						echo "Using user-provided IMAGE_TAG: ${params.IMAGE_TAG}"
						env.IMAGE_TAG = params.IMAGE_TAG
					}
				}
			}
		}


        stage('Apply ConfigMap') {
			steps {
				script {
					echo "Applying global ConfigMap..."
                    sh 'kubectl apply -f k8s/configmap/global-configmap.yaml'
                }
            }
        }

        stage('Setup PostgreSQL CRD') {
            steps {
                script {
                    def crdExists = sh(script: "kubectl get crds | grep postgresql.cnpg.io || true", returnStdout: true).trim()
                    if (!crdExists) {
                        echo "Installing CloudNativePG operator..."
                        sh 'kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/releases/cnpg-1.22.1.yaml'
                        sh 'kubectl rollout status deployment/cnpg-controller-manager -n cnpg-system --timeout=120s'
                    } else {
                        echo "CloudNativePG CRD already installed."
                    }
                }
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                script {
                    echo "Deploying PostgreSQL cluster..."
                    sh '''
                      kubectl apply -f k8s/postgres/postgres-secret.yaml
                      kubectl apply -f k8s/postgres/postgres-cluster.yaml
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
			when {
				expression { params.DEPLOY_TO_KUBERNETES }
            }
            steps {
				script {
					echo "Deploying build ID: ${params.BUILD_ID}, image tag: ${env.IMAGE_TAG}"
                    env.SERVICES.split().each { service ->
                        echo "=== Deploying ${service} with image tag ${env.IMAGE_TAG} ==="
                        sh """
                          helm upgrade --install ${service} ./k8s/${service}/helm \
                          	  --atomic=false \
                          	  --timeout 360s \
                              --set image.repository=${DOCKER_HUB_CREDS_USR}/${service} \
                              --set image.tag=${env.IMAGE_TAG} \
                              --set deployment.annotations.redeploy=\$(date +%s)
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
                          kubectl rollout status deployment/${service} --namespace=default --timeout=360s
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
    }

    post {
		success {
			echo "✅ Deployment successful!"
        }
        failure {
			echo "❌ Deployment failed!"
        }
    }
}
