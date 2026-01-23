# Creating an execution environment for the Ansible Collection for OpenShift Virtualization Migration

In order to be able to import this collection into AAP you first will need to create an Execution Environment and configure the EE to be able to talk to either a local automation hub or the one in the cloud. This must be done on a registered Red Hat Enterprise Linux server so you have access to all of the correct repositories to create the image.

## Install prerequisites

```shell
dnf install -y ansible-navigator buildah
```

Note: `ansible-builder` could instead be used instead, but `ansible-navigator` is a more fully featured utility.

## Set Automation Hub Environment Variables

The Execution Environment makes use of Ansible Content Collections from Red Hat Automation Hub. Obtain a token from Red Hat Automation Hub here and et the following environment variables.

```shell
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN=<token>
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN=<token>
```

A helper script is available in [scripts/setup_build_env.sh](../scripts/setup_build_env.sh) within the root project directory which contains the rest of the required environment variables to source content from Red Hat Automation Hub.

```shell
source ../scripts/setup_build_env.sh
```

## Create execution environment

Use the following commands to produce an Execution Environment

First, create a build context from the Execution Environment spec

```shell
ansible-builder create --output-filename=Containerfile
```

Use `buildah` to produce a new Execution Environment container image

```shell
buildah build --env 'ANSIBLE_GALAXY*' -t localhost/openshift-virtualization-migration-ee:latest context
```

This execution environment can not legally be distributed due to the vmware python modules included and must be recreated for each environment.
