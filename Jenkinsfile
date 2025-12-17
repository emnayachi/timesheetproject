pipeline {
    agent any

    environment {
        DOCKER_IMAGE    = 'emnayachi/timesheetproject'
        
        DOCKER_CREDS_ID = 'dockerhub-creds'
    }

    stages {
        stage('Hello World') {
            steps {
                echo 'Hello World !'
            }
        }

        stage('Checkout Git') {
            steps {
                git(
                    url: 'https://github.com/emnayachi/timesheetproject.git',
                    branch: 'master'
                )
            }
        }

        stage('Maven Build') {
            steps {
                sh label: 'Compilation Maven', script: '''
                    mvn clean compile
                '''
            }
        }

        stage('Analyse SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh label: 'Analyse SonarQube', script: '''
                        mvn sonar:sonar \\
                            -Dsonar.projectKey=timesheetproject \\
                            -Dsonar.host.url=$SONAR_HOST_URL \\
                            -Dsonar.token=$SONAR_AUTH_TOKEN
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh label: 'Construction de l\'image Docker', script: '''
                    # Vérification du Dockerfile (présent dans le repo)
                    if [ ! -f Dockerfile ]; then
                        echo "Erreur : Dockerfile non trouvé !"
                        exit 1
                    fi

                    # Build avec tag du build Jenkins + latest
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} \\
                                 -t ${DOCKER_IMAGE}:latest .
                    
                    echo "Image construite avec succès : ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                '''
            }
        }

        stage('Docker Push') {
            steps {
                // Tolérance aux problèmes temporaires de Docker Hub
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    timeout(time: 10, unit: 'MINUTES') {
                        withCredentials([usernamePassword(
                            credentialsId: DOCKER_CREDS_ID,
                            usernameVariable: 'DH_USER',
                            passwordVariable: 'DH_PASS'
                        )]) {
                            sh label: 'Login Docker Hub', script: '''
                                echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                            '''

                            sh label: 'Push des images', script: '''
                                docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                                docker push ${DOCKER_IMAGE}:latest
                            '''

                            sh label: 'Logout Docker Hub', script: '''
                                docker logout || true
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Build réussi ! Image Docker construite et poussée sur Docker Hub.'
            echo "Pour lancer l'application : docker run -d -p 8080:8080 ${DOCKER_IMAGE}:latest"
        }
        failure {
            echo 'Échec du build - Vérifiez la console pour les erreurs.'
        }
        unstable {
            echo 'Build instable (probablement un problème temporaire lors du push Docker Hub). L\'image est quand même construite localement.'
        }
    }
}
