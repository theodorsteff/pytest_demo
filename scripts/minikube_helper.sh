#!/usr/bin/env bash
set -euo pipefail

# Helper script for managing Minikube configuration and providing useful commands
# for the pytest-selenium project.

MEMORY=${MEMORY:-2048}
CPUS=${CPUS:-2}
K8S_VERSION=${K8S_VERSION:-v1.28.0}

usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
    start       Start Minikube with optimal settings for pytest-selenium
    stop        Stop Minikube cluster
    status      Show detailed status of Minikube and pods
    dashboard   Open Kubernetes dashboard
    clean       Clean up old pods and cached images
    tunnel      Create tunnel for LoadBalancer services
    help        Show this help message

Options:
    --memory    Memory in MB (default: 2048)
    --cpus      Number of CPUs (default: 2)
    --k8s-ver   Kubernetes version (default: v1.28.0)

Examples:
    $0 start --memory 4096 --cpus 4
    $0 status
    $0 clean
EOF
}

check_minikube() {
    if ! command -v minikube >/dev/null 2>&1; then
        echo "Error: minikube not found. Please install it first."
        exit 1
    fi
}

start_minikube() {
    echo "Starting Minikube with memory=${MEMORY}MB, cpus=${CPUS}, k8s=${K8S_VERSION}"
    
    # Ensure using docker driver and configure resources
    minikube config set driver docker
    minikube config set memory "$MEMORY"
    minikube config set cpus "$CPUS"
    
    # Start with optimal settings for pytest-selenium
    minikube start \
        --driver=docker \
        --kubernetes-version="$K8S_VERSION" \
        --mount-string="/var/run/docker.sock:/var/run/docker.sock" \
        --mount \
        --addons=dashboard \
        --addons=metrics-server \
        --addons=ingress

    # Wait for node to be ready
    echo "Waiting for node to be ready..."
    kubectl wait --for=condition=ready node/minikube --timeout=3m

    # Print status
    echo -e "\nNode Status:"
    kubectl get nodes -o wide
    
    echo -e "\nPod Status:"
    kubectl get pods --all-namespaces
    
    echo -e "\nAddons Status:"
    minikube addons list
}

stop_minikube() {
    echo "Stopping Minikube cluster..."
    minikube stop
}

show_status() {
    echo "=== Minikube Status ==="
    minikube status
    
    echo -e "\n=== Node Status ==="
    kubectl get nodes -o wide
    
    echo -e "\n=== Pod Status ==="
    kubectl get pods --all-namespaces
    
    echo -e "\n=== System Info ==="
    minikube ssh "free -h && df -h"
    
    echo -e "\n=== Service URLs ==="
    minikube service list
}

clean_minikube() {
    echo "Cleaning up Minikube environment..."
    
    # Delete completed pods
    kubectl delete pods --field-selector=status.phase==Succeeded --all-namespaces
    kubectl delete pods --field-selector=status.phase==Failed --all-namespaces
    
    # Clean docker images in minikube
    minikube ssh "docker system prune -af"
    
    echo "Cleanup complete"
}

start_dashboard() {
    echo "Starting Kubernetes dashboard..."
    minikube dashboard
}

start_tunnel() {
    echo "Creating tunnel for LoadBalancer services..."
    minikube tunnel
}

# Parse command line arguments
cmd="help"
while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|status|dashboard|clean|tunnel|help)
            cmd="$1"
            shift
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --cpus)
            CPUS="$2"
            shift 2
            ;;
        --k8s-ver)
            K8S_VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Execute command
check_minikube
case $cmd in
    start)
        start_minikube
        ;;
    stop)
        stop_minikube
        ;;
    status)
        show_status
        ;;
    dashboard)
        start_dashboard
        ;;
    clean)
        clean_minikube
        ;;
    tunnel)
        start_tunnel
        ;;
    help|*)
        usage
        ;;
esac