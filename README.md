# migration_factory_ees

Ansible Execution Environments supporting the Ansible Collection for OpenShift Virtualization Migration

## Execution Environments

Execution Environments for OpenShift Virtualization Migration are built using minimal base images for each AAP version for compatibility. The following images are available from quay.io [redhat-cop/openshift-virtualization-migration-ee](https://quay.io/redhat-cop/openshift-virtualization-migration-ee):

- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.4
- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.5
- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.6
- quay.io/redhat-cop/openshift-virtualization-migration-ee:2.7

**To access the execution environment you will need an access token to login to the private registry.**

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

This repository automatically builds and pushes a new image on every pipeline run to enable testing. Images built using the pipeline on new commits to the main branch are published to the internal quay registry every run with two tags, `<version>` and `latest-<version>`. Images are also built and pushed for pull request events to the main branch using the tags `<version>-dev` and `latest-<version>-dev`. In addition, a cron workflow is used to build and push nightly images to account for latest vulnerabilities fixes in the base images and any new release of the Ansible collections for OpenShift Virtualization Migration.

In order to push an image with a different tag (such as a version number or latest) a manual workflow execution is needed. This can be done through the UI by clicking on "Actions" -> "Build Execution Environments" in the left side navigation bar. From the workflow screen click "Run workflow" in the top right.

**NOTE** The workflow already contains the necessary credentials to push to quay.io/redhat-cop/openshift-virtualization-migration-ee, and does not expose an easy way to provide additional credentials for other repositories. If pushing to additional destinations are needed, reach out on the #forum-virt-migration-factory slack channel for support.

### Technical Details

The execution environment should include all the dependencies necessary to execute the Ansible Collection for OpenShift Virtualization Migration collection. It is important that the requirements.yml matches so that all collections are available.

## Notes on sharing image

The migration-factory-ee is stored in a private registry as it contains Red Hat Automation content that is not available without a valid subscription.

> Ansible validated content is only available with a valid subscription to Red Hat Ansible Automation Platform.
>
> Unlike Red Hat Ansible Certified Content, Ansible validated content is not supported by Red Hat or our partners.
>
> From the Red Hat Ansible Automation Platform 2.3 release, Ansible validated content is preloaded into private automation hub and can be updated manually by downloading the packages.

## Contributing

[See the contributors guide](CONTRIBUTING) for this repository and the [collection contributors repository](https://github.com/redhat-cop/openshift-virtualization-migration-documentation)

## Creating an execution environment for the Ansible Collection for OpenShift Virtualization Migration

In order to be able to import this collection into AAP you first will need to create an Execution Environment and configure the EE to be able to talk to either a local automation hub or the one in the cloud. This must be done on a registered Red Hat Enterprise Linux server so you have access to all of the correct repositories to create the image.

### Install prerequisites

```shell
dnf install -y ansible-builder podman trivy
```

### Set Automation Hub Environment Variables

The Execution Environment makes use of Ansible Content Collections from Red Hat Automation Hub. Obtain a token from [Red Hat Automation Hub](https://console.redhat.com/ansible/automation-hub/token) and set the following environment variables:

```shell
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN=<token>
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN=<token>
```

### Activation Key

Access to Red Hat repositories are required to build the Execution Environment. Visit [https://console.redhat.com/insights/registration](https://console.redhat.com/insights/registration) to generate an activation key for your organization and set the following environment variables:

```shell
export REDHAT_ORG=<organization>
export REDHAT_ACTIVATION_KEY=<activation_key>
```

### Targeting specific AAP version

The configuration for building execution environments make use of base images tailored to specific AAP versions. The base images are available at registry.redhat.io. Follow the instructions at [Red Hat Container Registry Authentication](https://access.redhat.com/articles/RegistryAuthentication) to obtain your credentials to the registry. In addition, each AAP version may require different versions of the collection dependencies as defined in `requirements.yml` in each AAP version directory.

### Create execution environment

A helper script is available in [scripts/build-ee-local.sh](scripts/build-ee-local.sh) within the root project which configures the environment variables, builds the container image using podman and scans for vulnerabilities using trivy. A custom rule "asymmetric-private-key-critical" defined in [trivy-secret.yaml](trivy-secret.yaml) is used to scan the image for secret keys generated by the subscription manager to ensure it is not left in the final built image.

```shell
source ./scripts/build-ee-local.sh
```
