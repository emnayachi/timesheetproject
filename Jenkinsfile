pipeline {
    agent any

    environment {
        DOCKER_IMAGE    = 'emnayachi/timesheetproject'
        DOCKER_CREDS_ID = 'jenkins-token'  
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
                sh label: 'Maven Package (génération du JAR)', script: '''
                    mvn clean package -Dmaven.test.skip=true
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
                    if [ ! -f Dockerfile ]; then
                        echo "Erreur : Dockerfile non trouvé !"
                        exit 1
                    fi

                    # Vérification que le JAR existe maintenant
                    if [ ! -f target/timesheet-devops-1.0.jar ]; then
                        echo "Erreur : JAR non généré dans target/ !"
                        ls -la target/
                        exit 1
                    fi

                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} \\
                                 -t ${DOCKER_IMAGE}:latest .
                    
                    echo "Image construite : ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                '''
            }
        }

        stage('Docker Push') {
            steps {
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

                            sh label: 'Logout', script: '''
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
            echo 'Build réussi ! Image Docker poussée sur Docker Hub : emnayachi/timesheetproject:latest'
            echo 'Pour lancer l\'app : docker run -d -p 8082:8082 emnayachi/timesheetproject:latest'
        }
        failure {
            echo 'Échec du build - Vérifiez la console pour les erreurs.'
        }
        unstable {
            echo 'Build instable (probablement problème de push Docker Hub). L\'image est construite localement.'
        }
    }
}
