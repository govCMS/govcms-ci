# govcms-ci

This is a base image intended for use in CI processes.

[![CircleCI](https://circleci.com/gh/govCMS/govcms-ci.svg?style=svg)](https://circleci.com/gh/govCMS/govcms-ci)

It is based on the amazee.io PHP (Drupal) image, with the addition of some extra tooling.

To build the CI image locally for a single platform, run the following:
```
IMAGE_TAG={your-desired-tag} docker buildx bake --progress=plain --pull --set ci.platform=linux/{arm64/amd64} -f bake.hcl ci --print
IMAGE_TAG={your-desired-tag} docker buildx bake --progress=plain --pull --set ci.platform=linux/{arm64/amd64} -f bake.hcl ci
```

To build the CI on multi-arch, you first need to create a buildx builder instance.
```
docker buildx create --name multiarch-amd-arm --platform linux/amd64,linux/arm64 --use
IMAGE_TAG={your-desired-tag} docker buildx bake --progress=plain --pull -f bake.hcl ci --print
IMAGE_TAG={your-desired-tag} docker buildx bake --progress=plain --pull -f bake.hcl ci
IMAGE_TAG={your-desired-tag} docker buildx bake --progress=plain --pull -f bake.hcl ci --push
```

## Ansible creator image

[Ansible creator](https://quay.io/repository/ansible/creator-ee) contains the tools required for linting and testing Ansible playbooks.

The image pull is failing for some reason on Gitlab, so it has to be built locally.

```shell
CREATOR_EE_VERSION=${CREATOR_EE_VERSION:-v0.5.2}
git clone -b ${CREATOR_EE_VERSION} https://github.com/ansible/creator-ee.git
cd creator-ee
docker build -t gitlab-registry-production.govcms.amazee.io/govcms/govcms-ci/ansible-creator-ee:${CREATOR_EE_VERSION} .
docker push gitlab-registry-production.govcms.amazee.io/govcms/govcms-ci/ansible-creator-ee:${CREATOR_EE_VERSION}
```
