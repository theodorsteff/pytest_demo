pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pytest-selenium
spec:
  containers:
  - name: python
    image: python:3.8-slim
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "1Gi"
        cpu: "1"
  - name: xvfb
    image: selenium/standalone-firefox:latest
    securityContext:
      privileged: true
    env:
    - name: START_XVFB
      value: "true"
    resources:
      requests:
        memory: "1Gi"
        cpu: "1"
      limits:
        memory: "2Gi"
        cpu: "2"
'''
        }
    }

    environment {
        FIREFOX_BINARY = "/usr/bin/firefox"  // Path to Firefox in the Selenium container
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Python Environment') {
            steps {
                container('python') {
                    sh '''
                        python -m venv .venv
                        . .venv/bin/activate
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                container('xvfb') {
                    sh '''
                        # Wait for Xvfb and Firefox to be ready
                        sleep 5
                        
                        # Activate virtual environment and run tests
                        . .venv/bin/activate
                        xvfb-run -s "-screen 0 1920x1080x24" pytest -v
                    '''
                }
            }
        }
    }

    post {
        always {
            // Archive the test results and logs
            junit '**/test-results/*.xml'
            archiveArtifacts artifacts: '**/test-results/*.xml, geckodriver.log', allowEmptyArchive: true
        }
    }
}