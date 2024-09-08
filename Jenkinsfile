pipeline {
    agent any

    tools {
        maven 'maven3'
        jdk 'jdk17'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Git-Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/arpita199812/Taskmaster-pro.git'
            }
        }

        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('Unit-Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Trivy-FS') {
            steps {
                sh 'trivy fs --format table -o fs.html .'
            }
        }

        stage('Sonar-Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=taskmaster \
                    -Dsonar.projectKey=taskmaster \
                    -Dsonar.java.binaries=target
                    '''
                }
            }
        }

        stage('Build-Application') {
            steps {
                sh 'mvn package'
            }
        }

        stage('Publish Artifact') {
            steps {
                withMaven(globalMavenSettingsConfig: 'settings-maven', jdk: 'jdk17', maven: 'maven3', traceability: true) {
                    sh 'mvn deploy'
                }
            }
        }

        stage('Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker build -t arpita199812/taskmaster-pro:latest .'
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --format table -o image.html arpita199812/taskmaster-pro:latest'
            }
        }

        stage('Docker Push to Registry') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker push arpita199812/taskmaster-pro:latest'
                    }
                }
            }
        }

        stage('K8 Deploy') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'taskpro-cluster', contextName: '', credentialsId: 'k8-token', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'api-server-endpoint-url') {
                    sh 'kubectl apply -f deployment-service.yml'
                    sleep 30
                }
            }
        }

        stage('Verify k8 Deploy') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'taskpro-cluster', contextName: '', credentialsId: 'k8-token', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'api-server-endpoint-url') {
                    sh 'kubectl get pods -n webapps'
                    sh 'kubectl get svc -n webapps'
                }
            }
        }
    }
}
