Docker-based test runner

This directory contains a Docker-based test runner that builds an image containing Firefox and your tests, runs pytest inside the container, and writes JUnit XML results to `test-results/` so Jenkins can archive them.

Files
- Dockerfile.test - Dockerfile based on `selenium/standalone-firefox` with Python and project code
- run_tests_in_container.sh - Entrypoint that runs pytest and writes junit xml to `/workspace/test-results`

Usage (local)

Build the image:

```bash
docker build -t pytest_demo_test -f docker/Dockerfile.test .
```

Run tests locally and save results to a host directory (current dir will be used by default):

```bash
# Run container and mount current working directory into /workspace so test-results are persisted
docker run --rm --shm-size=1g -v "$(pwd):/workspace" pytest_demo_test

# After run, see results in ./test-results/junit-results.xml
```

Jenkins

Use `Jenkinsfile.docker` at the repo root. Notes:
- The pipeline builds the image, runs the container (mounting the Jenkins workspace) and archives `test-results/*.xml` using the `junit` step.
- To publish the built image to a registry, set the `DOCKER_PUSH` environment variable to `true` and configure Jenkins credentials with ids `docker-username` and `docker-password`. Optionally set `DOCKER_REGISTRY`.

Tips
- The container uses `--shm-size=1g` to avoid Firefox crashes due to shared memory limits.
- Make sure the Jenkins agent that runs the pipeline has Docker installed and the Jenkins user can run `docker`.
- If you want to push images to Docker Hub or another registry, create credentials in Jenkins and reference them as shown in `Jenkinsfile.docker`.
