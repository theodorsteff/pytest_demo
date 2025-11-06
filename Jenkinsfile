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
  volumes:
    - name: docker-socket
      hostPath:
        path: /var/run/docker.sock
  containers:
  - name: python
    image: python:3.11-slim  # Updated to newer Python
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "256Mi"  # Reduced since we're not doing heavy processing
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
  - name: selenium
    image: selenium/standalone-firefox:latest
    securityContext:
      privileged: true  # Required for Docker-in-Docker
    volumeMounts:
      - name: docker-socket
        mountPath: /var/run/docker.sock
    env:
    - name: START_XVFB
      value: "true"
    - name: SE_NODE_MAX_SESSIONS
      value: "4"
    - name: SE_NODE_OVERRIDE_MAX_SESSIONS
      value: "true"
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1"
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