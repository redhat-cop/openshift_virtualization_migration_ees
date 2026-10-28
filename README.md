# migration_factory_ees

Ansible Execution Environments supporting the Ansible Collection for OpenShift Virtualization Migration

## Execution Environments

The following Execution Environments are available:

**To access the execution environment you will need an access token to login to the private registry.**

### Latest Release

This image is available from quay.io

[redhat-cop/openshift-virtualization-migration-ee](quay.io/redhat-cop/openshift-virtualization-migration-ee)

### Development Image

A image is available for use by developers building content for the collection. It includes content from the latest EE image with the openshift-virtualization-migration collection omitted to enable development workflows.

[Development Image - quay.io/redhat-cop/openshift-virtualization-migration-ee:devel](openshift-virtualization-migration-ee-devel)


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

#### Technical Details

The execution environment should include all the dependencies necessary to execute the Ansible Collection for OpenShift Virtualization Migration collection. It is important that the requirements.yml matches so that all collections are available.

## Notes on sharing image

The openshift-virtualization-migration-ee image is stored in a private registry as it contains Red Hat Automation and supporting content that is not available without a valid subscription.

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
