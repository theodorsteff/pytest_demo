Pytest + Selenium demo

This small demo shows how to use pytest with Selenium (Firefox) to open https://www.google.com and verify the page title.

Requirements
- Python 3.8+
- Firefox browser (either system Firefox, or download portable Firefox - see below)
- xvfb package if running headless tests without a display server

Quick start

1) Create a virtual environment and activate it

```bash
python -m venv .venv
source .venv/bin/activate
```

2) Install dependencies

```bash
pip install -r requirements.txt

# On some systems you may need xvfb to run headless:
sudo apt install -y xvfb
```

3) Get Firefox

If your system's Firefox is a snap package or otherwise incompatible, you can use a portable Firefox. The included helper script makes this easy:

```bash
# Download Firefox to ./firefox (safe, won't overwrite existing):
./scripts/get_firefox.sh

# Force re-download (replace existing ./firefox):
./scripts/get_firefox.sh --force

# Skip download if ./firefox exists:
./scripts/get_firefox.sh --keep

# Override architecture (default: auto-detected):
./scripts/get_firefox.sh --arch=linux-aarch64  # for ARM64
./scripts/get_firefox.sh --arch=linux64        # for x86_64

# After download, use the local Firefox:
export FIREFOX_BINARY="$(pwd)/firefox/firefox"
```

Note: The helper script is idempotent and safe by default:
- If `./firefox` doesn't exist: downloads and unpacks Firefox there
- If `./firefox` exists: refuses to overwrite unless `--force` is passed
- With `--keep`: skips download if `./firefox` exists (useful in CI)
```

4) Run tests

```bash
# Run tests (assumes working display):
pytest -q

# Or run tests headless under xvfb:
xvfb-run -s "-screen 0 1920x1080x24" pytest -q
```

5) Complete command with force firefox re-download would look like this

```bash
# Force re-download firefox portable executable, run tests headless under xvfb:
./scripts/get_firefox.sh --force FIREFOX_BINARY="$(pwd)/firefox/firefox" xvfb-run -s "-screen 0 1920x1080x24" /home/thesteff/workspace/pytest_demo/.venv/bin/python -m pytest -q
```

Jenkins and Kubernetes Setup

This project includes Jenkins pipeline configuration for running tests in a Kubernetes environment. Here's how to set it up:

1. Install Required Jenkins Plugins
   - Kubernetes plugin
   - Pipeline plugin (usually pre-installed)
   - JUnit plugin

2. Set up Local Kubernetes (Minikube)
```bash
# Install Minikube and dependencies
sudo apt-get update
sudo apt-get install -y virtualbox virtualbox-ext-pack

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start
```

3. Get Kubernetes Credentials for Jenkins
```bash
# Create directory for certificates
mkdir -p ~/jenkins-k8s-certs

# Get the certificates
minikube ssh sudo cat /var/lib/minikube/certs/ca.crt > ~/jenkins-k8s-certs/ca.crt
minikube ssh sudo cat /var/lib/minikube/certs/apiserver-kubelet-client.crt > ~/jenkins-k8s-certs/client.crt
minikube ssh sudo cat /var/lib/minikube/certs/apiserver-kubelet-client.key > ~/jenkins-k8s-certs/client.key
```

4. Configure Jenkins Kubernetes Integration
   - Go to `Manage Jenkins` > `Manage Credentials`
   - Click on `(global)` domain
   - Click `Add Credentials`
   - Select `Kubernetes Service Account`
   - Fill in:
     - ID: `minikube-credentials` (or your preference)
     - Description: "Minikube cluster credentials"
     - Copy contents from:
       - `~/jenkins-k8s-certs/ca.crt` → "Certificate Authority Data"
       - `~/jenkins-k8s-certs/client.crt` → "Client Certificate Data"
       - `~/jenkins-k8s-certs/client.key` → "Client Key Data"

5. Configure Kubernetes Cloud in Jenkins
   - Go to `Manage Jenkins` > `Configure System`
   - Find "Cloud" section
   - Add new Kubernetes cloud:
     ```
     Name: kubernetes
     Kubernetes URL: https://<minikube-ip>:8443  (get IP from 'minikube ip')
     Kubernetes Namespace: default
     Credentials: select the one created above
     Jenkins URL: http://<jenkins-ip>:8080
     ```

6. Create Jenkins Pipeline
   - Create new Pipeline job
   - Configure Git repository:
     - Repository URL: your GitHub repo URL
     - Branch Specifier: `*/main`
     - Script Path: `Jenkinsfile`

7. Optional: Set up Kubernetes RBAC
```bash
kubectl create serviceaccount jenkins
kubectl create rolebinding jenkins-admin-binding --clusterrole=admin --serviceaccount=default:jenkins
```

The included Jenkinsfile will automatically:
- Create a pod with Python and Selenium containers
- Run the tests in the containerized environment
- Report test results

Notes and troubleshooting
- The project uses `webdriver-manager` to download a matching geckodriver automatically.
- If Firefox fails to start:
  - Try a portable Firefox (see above "Get Firefox" steps).
  - Or install Firefox ESR if available: `sudo apt install -y firefox-esr`
  - If using system Firefox and it's a snap package, you may need to set `FIREFOX_BINARY` to point to a non-snap Firefox binary.
- To run non-headless (debug), edit `conftest.py` and set `options.headless = False`.
