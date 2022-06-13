variable "CI_REGISTRY" {
    default = "gitlab-registry-production.govcms.amazee.io"
}

variable "IMAGE_TAG" {
    default = "edge"
}

variable GOVCMS_GITHUB_TOKEN {
    default = $GOVCMS_GITHUB_TOKEN
    sensitive = true
    type = string
}

group "default" {
    targets = ["ci", "dind"]
}

target "ci" {
    dockerfile = "govcms-ci.Dockerfile"
    platforms = ["linux/amd64", "linux/arm64"]
    tags = ["${CI_REGISTRY}/govcms/govcms-ci:${IMAGE_TAG}"]
    args = {
        GOVCMS_GITHUB_TOKEN = GOVCMS_GITHUB_TOKEN
    }
}

target "dind" {
    dockerfile = "dind.Dockerfile"
    platforms = ["linux/amd64", "linux/arm64"]
    tags = ["${CI_REGISTRY}/govcms/govcms-ci/dind:latest"]
}
