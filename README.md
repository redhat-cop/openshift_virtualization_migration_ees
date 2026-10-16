# migration_factory_ees

Ansible Execution Environments supporting the Ansible Collection for OpenShift Virtualization Migration

## Execution Environments

The following Execution Environments are available:

**To access the execution environment you will need an access token to login to the private registry.**

### Latest Release

This image is available from quay.io

[redhat-cop/openshift-virtualization-migration-ee](quay.io/redhat-cop/openshift-virtualization-migration-ee)

### Development Image

This image is published to the RH internal quay on every update of the main branch. VPN is required to access.

[Development Image - migration-factory/openshift-virtualization-migration-ee](images.paas.redhat.com/migration-factory/openshift-virtualization-migration-ee:dev)


#### Pulling the image

To access the execution environment you will need an access token to login to the private registry.

```bash
$ podman login quay.io/redhat-cop
$ podman pull quay.io/redhat-cop/openshift-virtualization-migration-ee:latest
```

#### Inspecting the image using skopeo

To obtain more information on the images, or view all the available tags you can use the skopeo command as follows:

```bash
$ skopeo list-tags docker://quay.io/redhat-cop/openshift-virtualization-migration-ee
```

#### Publishing a new image

This repository automatically builds and pushes a new image on every pipeline run to enable testing. Images built using the pipeline are published to the internal quay registry every run with two tags, 'dev' and 'dev-pipeline-build'.

**NOTE The public image is not currently published via the pipeline. That is a manual step that must be done when we are ready for a new release.**

In order to push an image with a different tag (such as a version number or latest) a manual pipeline execution is needed. This can be done through the UI by clicking on "Build" -> "Pipelines" in the left side navigation bar. From the Pipelines screen click "New Pipeline" in the top right.

You will be presented with a list of variables that can be overridden. Modifying the value for "BUILDAH_OUTPUT_TAG" will override the default generated tag to what is needed.

**NOTE** The pipeline already contains the necessary credentials to push to quay.io/redhat-cop/openshift-virtualization-migration-ee, and does not expose an easy way to provide additional credentials for other repositories. If pushing to additional destinations are needed, reach out on the #forum-virt-migration-factory slack channel for support.

#### Technical Details

The execution environment should include all the dependencies necessary to execute the Ansible Collection for OpenShift Virtualization Migration collection. It is important that the requirements.yml matches so that all collections are available.

## Notes on sharing image

The migration-factory-ee is stored in a private registry as it contains Red Hat Automation content that is not available without a valid subscription.

>>>

    Ansible validated content is only available with a valid subscription to Red Hat Ansible Automation   Platform.

    Unlike Red Hat Ansible Certified Content, Ansible validated content is not supported by Red Hat or our partners.

    From the Red Hat Ansible Automation Platform 2.3 release, Ansible validated content is preloaded into private automation hub and can be updated manually by downloading the packages.

>>>

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

## Contributing

[See the contributors guide](CONTRIBUTING) for this repository and the [collection contributors repository](https://github.com/redhat-cop/openshift-virtualization-migration-documentation)
