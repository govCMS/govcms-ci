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

