# Development Workflow

This guide explains the recommended workflow for developing and testing with this project, utilizing the provided tools and Kubernetes integration.

## Initial Setup

1. Clone and prepare the environment:
```bash
# Clone repository
git clone https://github.com/theodorsteff/pytest_demo.git
cd pytest_demo

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

2. Set up the Kubernetes environment:
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Initial setup with Docker and Minikube
./scripts/setup_minikube_docker.sh 2048

# Verify cluster is ready
./scripts/minikube_helper.sh status
```

## Daily Development Workflow

### 1. Starting Your Day

```bash
# Start/resume the Minikube cluster
./scripts/minikube_helper.sh start

# Check cluster health
./scripts/minikube_helper.sh status

# Open Kubernetes dashboard in browser (optional)
./scripts/minikube_helper.sh dashboard
```

### 2. Running Tests Locally

a) With system Firefox:
```bash
# Regular mode (needs display)
pytest -v

# Headless mode
xvfb-run -s "-screen 0 1920x1080x24" pytest -v
```

b) With portable Firefox:
```bash
# Download Firefox if needed
./scripts/get_firefox.sh --keep

# Run tests with portable Firefox
FIREFOX_BINARY="$(pwd)/firefox/firefox" pytest -v
```

### 3. Testing in Kubernetes

Manual pod deployment for quick tests:
```bash
# Deploy test pod
kubectl apply -f k8s/pod.yaml

# Check pod status
kubectl get pods

# Execute tests in pod
kubectl exec -it <pod-name> -- pytest -v
```

### 4. Testing in Jenkins

#### Prerequisites

1. Jenkins Installation
   ```bash
   # If Jenkins isn't installed, install it:
   curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
     /usr/share/keyrings/jenkins-keyring.asc > /dev/null
   echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
     https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
     /etc/apt/sources.list.d/jenkins.list > /dev/null
   sudo apt update
   sudo apt install jenkins
   ```

2. Required Jenkins Plugins
   - Install via Manage Jenkins > Plugins:
     - Kubernetes Plugin
     - Pipeline Plugin
     - Git Plugin
     - JUnit Plugin

3. Kubernetes Integration Setup
   ```bash
   # Ensure Minikube is running
   ./scripts/minikube_helper.sh status

   # Get Minikube IP and certificates
   MINIKUBE_IP=$(minikube ip)
   mkdir -p ~/jenkins-k8s-certs
   minikube ssh sudo cat /var/lib/minikube/certs/ca.crt > ~/jenkins-k8s-certs/ca.crt
   minikube ssh sudo cat /var/lib/minikube/certs/apiserver-kubelet-client.crt > ~/jenkins-k8s-certs/client.crt
   minikube ssh sudo cat /var/lib/minikube/certs/apiserver-kubelet-client.key > ~/jenkins-k8s-certs/client.key
   ```

#### Jenkins Configuration

1. Add Kubernetes Cloud
   - Navigate to Manage Jenkins > Configure System
   - Add Cloud > Kubernetes
   - Configure:
     ```
     Name: kubernetes
     Kubernetes URL: https://<MINIKUBE_IP>:8443
     Kubernetes Namespace: default
     Credentials: Add > Kubernetes Service Account
     ```

2. Add Credentials
   - In Add Credentials form:
     ```
     Kind: Kubernetes Service Account
     ID: minikube-credentials
     Description: Minikube cluster credentials
     ```
   - Copy contents from:
     - `~/jenkins-k8s-certs/ca.crt` → Certificate Authority Data
     - `~/jenkins-k8s-certs/client.crt` → Client Certificate Data
     - `~/jenkins-k8s-certs/client.key` → Client Key Data

#### Development Workflow

1. Create Jenkins Pipeline
   ```bash
   # In Jenkins UI:
   New Item > Pipeline
   Name: pytest-selenium-demo
   ```

2. Configure Pipeline
   - Pipeline Configuration:
     ```
     Pipeline from SCM
     SCM: Git
     Repository URL: https://github.com/theodorsteff/pytest_demo.git
     Branch Specifier: */main
     Script Path: Jenkinsfile
     ```

3. Development Cycle
   ```bash
   # 1. Make changes locally and test
   pytest -v

   # 2. Commit and push changes
   git commit -am "your changes"
   git push origin main

   # 3. Build in Jenkins
   # Either:
   # - Click "Build Now" in Jenkins UI
   # - Or use Jenkins CLI:
   java -jar jenkins-cli.jar -s http://localhost:8080/ build pytest-selenium-demo

   # 4. Monitor build
   # - View console output in Jenkins UI
   # - Or use Jenkins CLI:
   java -jar jenkins-cli.jar -s http://localhost:8080/ console pytest-selenium-demo
   ```

4. Review Results
   - Check test results in Jenkins UI
   - Review artifacts (logs, reports)
   - Check Kubernetes pod status:
     ```bash
     ./scripts/minikube_helper.sh status
     ```

#### Troubleshooting Jenkins Builds

1. Pod Issues
   ```bash
   # Check pod status
   kubectl get pods

   # Get pod logs
   kubectl logs <pod-name>

   # Describe pod for events
   kubectl describe pod <pod-name>
   ```

2. Jenkins Connection Issues
   ```bash
   # Verify Minikube is running
   ./scripts/minikube_helper.sh status

   # Check Jenkins can reach Minikube
   curl -k https://<MINIKUBE_IP>:8443
   ```

3. Resource Issues
   ```bash
   # Check node resources
   kubectl describe node minikube

   # Clean up if needed
   ./scripts/minikube_helper.sh clean
   ```

### 5. Resource Management

Monitor and manage cluster resources:
```bash
# View detailed status
./scripts/minikube_helper.sh status

# Clean up resources when needed
./scripts/minikube_helper.sh clean

# Stop cluster at end of day
./scripts/minikube_helper.sh stop
```

## Common Tasks

### Updating Firefox

```bash
# Force update portable Firefox
./scripts/get_firefox.sh --force

# Or update only if not present
./scripts/get_firefox.sh --keep
```

### Managing Minikube Resources

```bash
# Restart with more resources
./scripts/minikube_helper.sh start --memory 4096 --cpus 4

# Enable load balancer access
./scripts/minikube_helper.sh tunnel
```

### Debugging

1. Kubernetes issues:
```bash
# Check detailed status
./scripts/minikube_helper.sh status

# View pod logs
kubectl logs <pod-name>

# Access dashboard
./scripts/minikube_helper.sh dashboard
```

2. Firefox/Selenium issues:
```bash
# Try portable Firefox
./scripts/get_firefox.sh --force
FIREFOX_BINARY="$(pwd)/firefox/firefox" pytest -v

# Run without headless mode
# Edit conftest.py and set options.headless = False
pytest -v
```

## Best Practices

1. **Resource Management**
   - Clean up resources regularly with `./scripts/minikube_helper.sh clean`
   - Stop cluster when not in use with `./scripts/minikube_helper.sh stop`
   - Monitor resource usage via dashboard or status command

2. **Testing**
   - Run tests locally first before pushing to CI
   - Use portable Firefox for consistent environment
   - Use headless mode for CI/automated testing

3. **Kubernetes Integration**
   - Keep Minikube updated to latest stable version
   - Use the dashboard for debugging
   - Clean up completed pods and cached images regularly

4. **Version Control**
   - Keep Firefox downloads out of git (they're in .gitignore)
   - Commit changes to helper scripts
   - Update documentation when changing workflows

## Troubleshooting

### Common Issues

1. **Minikube won't start**
   - Check Docker service is running
   - Verify resource allocation
   - Try cleaning and restarting: `./scripts/minikube_helper.sh clean && ./scripts/minikube_helper.sh start`

2. **Tests fail in Kubernetes**
   - Check pod status and logs
   - Verify Firefox binary path
   - Ensure sufficient resources allocated

3. **Jenkins pipeline issues**
   - Verify Kubernetes plugin configuration
   - Check node connectivity
   - Review pod template in Jenkinsfile

### Getting Help

1. Check the logs:
   - Kubernetes: `kubectl logs <pod-name>`
   - Minikube: `minikube logs`
   - Firefox: `geckodriver.log`

2. Use the dashboard:
   ```bash
   ./scripts/minikube_helper.sh dashboard
   ```

3. Get detailed status:
   ```bash
   ./scripts/minikube_helper.sh status
   ```