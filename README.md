# docker-bitcoind
## Docker

This project is for xapo case study. Bitcoin core project used for run bitcoind. For detailed information visit: https://bitcoincore.org

A non-root user(bitcoin) used for docker run. Bitcoind daemon configuration can be customized via bitcoin.conf.

Aquasec trivy used for security scanning. We can change fail threshold by chaning --severity parameter. We can use multiple threshold by separating commas:

`--severity HIGH,CRITICAL`.

Detailed info: https://aquasecurity.github.io/trivy/v0.19.2/vulnerability/examples/filter/

Available parameters:

`HIGH`

`CRITICAL`

`MEDIUM`

`LOW`

## Pipeline
Pipeline has two jobs:
build-artifact:

    checkout: Checkouts code form GitHub repository

    setup_remote_docker: Setups a remote docker daemon. CircleCI handles this stage by itself.

    Build Docker Image: Building and pushing docker image

    Scan Image: Image scanning process. If the image has one or more vulnerabilies in range of provided severity the pipeline fails and pushing step will not worked. We prevent vulnerable image to reach out image registry by this way.

    Push Docker Image: Pushing image to given registry. `$DOCKER_LOGIN` and `$DOCKER_PASSWORD` variables set on CircleCI UI.

deploy_infrastructure:

    - checkout
    - terraform/init:
        path: .
    - terraform/validate:
        path: .
    - terraform/fmt:
        path: .
    - terraform/plan:
        path: .
    - terraform/apply:
        var: "IMAGE=veyselsahin16/docker-bitcoind:0.1.${CIRCLE_BUILD_NUM},access_key=${access_key},secret_key=${secret_key}"
