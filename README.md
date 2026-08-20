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

## Contributing

[See the contributors guide](CONTRIBUTING) for this repository and the [collection contributors repository](https://github.com/redhat-cop/openshift-virtualization-migration-documentation)
