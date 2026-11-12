# openshift-virtualization-migration-ee

Ansible Execution Environments supporting the Ansible Collection for OpenShift Virtualization Migration

## Execution Environments

Execution Environments for OpenShift Virtualization Migration are built using minimal base images for each AAP version for compatibility. The following images are available from quay.io [redhat-cop/openshift-virtualization-migration-ee](https://quay.io/redhat-cop/openshift-virtualization-migration-ee):

- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.4
- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.5
- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.6
- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.7

### Pulling the image

To access the execution environment you will need an access token to login to the private registry.

```bash
$ podman login quay.io/redhat-cop
$ podman pull quay.io/redhat-cop/openshift-virtualization-migration-ee:2.7
```

### Inspecting the image using skopeo

To obtain more information on the images, or view all the available tags you can use the skopeo command as follows:

```bash
$ skopeo list-tags docker://quay.io/redhat-cop/openshift-virtualization-migration-ee
```

### Publishing a new image

This repository automatically builds and pushes a new image on every CI workflow run to enable testing. Images with tags `<version>` and `latest-<version>` are built and published to the quay registry on every new commits to the main branch. Images are also built and pushed for pull request events to the main branch using the tags `<version>-dev` and `latest-<version>-dev`. In addition, a cron workflow is used to build and push nightly images to account for latest vulnerabilities fixes in the base images and any new release of the Ansible collections for OpenShift Virtualization Migration.

In order to push an image with a different tag (such as a version number or latest) a manual workflow execution is needed. This can be done through the UI by clicking on "Actions" -> "Build Execution Environments" in the left side navigation bar. From the workflow screen click "Run workflow" in the top right.

**NOTE** The workflow already contains the necessary credentials to push to `quay.io/redhat-cop/openshift-virtualization-migration-ee`, and does not expose an easy way to provide additional credentials for other repositories. If pushing to additional destinations are needed, reach out on the #forum-virt-migration-factory slack channel for support.

### Technical Details

The execution environment should include all the dependencies necessary to execute the Ansible Collection for OpenShift Virtualization Migration collection. It is important that the `requirements.yml` matches so that all collections are available.

## Notes on sharing image

The `openshift-virtualization-migration-ee` image is stored in a private registry as it contains Red Hat Automation content that is not available without a valid subscription.

> Ansible validated content is only available with a valid subscription to Red Hat Ansible Automation Platform.
>
> Unlike Red Hat Ansible Certified Content, Ansible validated content is not supported by Red Hat or our partners.
>
> From the Red Hat Ansible Automation Platform 2.3 release, Ansible validated content is preloaded into private automation hub and can be updated manually by downloading the packages.

## CI/CD and Security Scanning

### Automated Image Building

The `Build Execution Environments` workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)) builds and publishes images automatically on:
- Every push to `main`
- Every pull request targeting `main`
- A daily cron schedule
- Manual `workflow_dispatch`

Images are built for each supported AAP version (`2.4`, `2.5`, `2.6`, `2.7`) in parallel via a matrix strategy. Each version produces a multi-architecture image (`linux/amd64`, `linux/arm64`).

### Vulnerability Scanning

Every built image is scanned with [Trivy](https://trivy.dev) **before** being pushed to the registry. The scan is configured in [trivy.yaml](trivy.yaml):

- Only `CRITICAL` severity findings are reported.
- Any `CRITICAL` finding causes the pipeline to fail (`exit-code: 1`), blocking the push.
- Scan results are uploaded to the GitHub Security tab in SARIF format.

The Trivy vulnerability DB and Java DB are downloaded once at the start of each workflow run (before the matrix fan-out) using a dedicated reusable workflow ([.github/workflows/_populate-trivy-cache.yml](.github/workflows/_populate-trivy-cache.yml)) and shared with all matrix jobs via the GitHub Actions cache. This guarantees the DB is always present regardless of how the workflow was triggered.

### Custom Secret Scanning Rule

Trivy is also configured to scan for secrets using a custom rule file ([trivy-secret.yaml](trivy-secret.yaml)). The rule `asymmetric-private-key-critical` detects PEM-encoded asymmetric private keys embedded in any image layer.

**Why this rule exists**: the container build process calls `subscription-manager register` inside a `RUN` instruction to activate a Red Hat subscription and pull licensed packages. This writes entitlement certificates and a private key to `/etc/pki/entitlement/` inside the layer. A subsequent `RUN` instruction calls `subscription-manager unregister` to clean up. If that register step is executed in the wrong stage of a multi-stage build, the private key is frozen into a layer of the image filesystem irrespective of a subsequent call to `subscription-manager unregister` and would be exposed to anyone who pulls the image.

The built-in Trivy `private-key` detection rule reports such findings at `HIGH` severity, which would pass undetected under the `CRITICAL`-only filter. The custom rule re-declares the same regex pattern at `CRITICAL` severity so that any leftover entitlement key is treated as a hard blocker and the push is rejected.

## Building an Execution Environment locally

In order to build and test an Execution Environment locally you will need to configure access to the relevant registries and content hubs because the build process calls `subscription-manager` inside a container layer to pull packages from Red Hat repositories.

### Repository structure

Each supported AAP version has its own directory containing four files:

| File | Purpose |
|---|---|
| `execution-environment.yml` | EE definition: base image, builder stages, build arguments |
| `requirements.yml` | Ansible collections to install |
| `requirements.txt` | Python packages to install |
| `bindep.txt` | System packages to install |

### Install prerequisites

Install `podman` via dnf and `ansible-builder` via pip:

```shell
dnf install -y podman
pip install ansible-builder
```

Trivy is also required to scan the built image for vulnerabilities. Follow the [Trivy installation instructions](https://trivy.dev/latest/getting-started/installation/) for your operating system.

### Set Automation Hub environment variables

The Execution Environment makes use of Ansible Content Collections from Red Hat Automation Hub. Obtain a token from [Red Hat Automation Hub](https://console.redhat.com/ansible/automation-hub/token) and set the following environment variables:

```shell
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN=<token>
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN=<token>
```

### Set activation key environment variables

Access to Red Hat repositories is required to build the Execution Environment. Visit [https://console.redhat.com/insights/registration](https://console.redhat.com/insights/registration) to generate an activation key for your organization and set the following environment variables:

```shell
export REDHAT_ORG=<organization>
export REDHAT_ACTIVATION_KEY=<activation_key>
```

### Login to Red Hat Container Registry

The base images for each EE version are pulled from `registry.redhat.io` during the build. Follow the instructions at [Red Hat Container Registry Authentication](https://access.redhat.com/articles/RegistryAuthentication) to obtain your credentials, then login:

```shell
podman login registry.redhat.io
```

### Build the execution environment

A helper script [scripts/build-ee-local.sh](scripts/build-ee-local.sh) configures the galaxy environment variables, builds the container image using podman, and scans it for vulnerabilities using trivy. The custom rule defined in [trivy-secret.yaml](trivy-secret.yaml) ensures no entitlement key is accidentally left in the final image.

By default the script targets AAP 2.7. Pass the AAP version as the first argument to build a different version:

```shell
# Build for AAP 2.7 (default)
bash ./scripts/build-ee-local.sh

# Build for a specific AAP version
bash ./scripts/build-ee-local.sh 2.6
```

### Verify the image

After a successful build, confirm the image is available locally:

```shell
podman image ls openshift-virtualization-migration-ee
```

## Contributing

[See the contributors guide](CONTRIBUTING) for this repository and the [collection contributors repository](https://github.com/redhat-cop/openshift-virtualization-migration-documentation)
