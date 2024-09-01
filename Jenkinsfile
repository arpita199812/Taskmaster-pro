pipeline {
    agent any
    
    tools {
        maven 'maven3'
        jdk 'java17'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_CREDENTIALS_ID = 'docker-hub-id'
    }
        

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/arpita199812/Taskmaster-pro.git'
            }
        }
        stage('Clean Install') {
            steps {
                sh 'mvn clean install'
            }
        }
        
        stage('Sonarqube-scan') {
            steps {
                script {
                     withSonarQubeEnv(credentialsId: 'sonar-token') {
                        sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=taskmaster-pro \
                            -Dsonar.projectKey=taskmaster-pro -Dsonar.java.binaries=target'''
                    }
                }
            }
        }
        stage('Quality-Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token' 
                }
            }
        }
        stage('OWASAP-Dependency-Check') {
            steps {
                script {
                    env.DEPENDENCYCHECK_APIKEY = 'nvd-api-key'
                    dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'Dependency-check' 
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        stage('Docker') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-hub-id', toolName: 'docker', url: 'https://index.docker.io/v1/') {
                    sh 'docker build -t arpita199812/taskmaster-pro:v2 .'
                    sh 'docker run -d --name task -p 5000:8080 arpita199812/taskmaster-pro:v2'
                    sh 'docker push arpita199812/taskmaster-pro:v2'
                    }
                }
            }
        }
         stage('Trivy Scan') {
            steps {
                    sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --scanners vuln arpita199812/taskmaster-pro:v2'
                }
            }
        }
    }
