# Introduction
* lib_docker.sh is a collection of shell functions I use in conjunction with my "[lib_shell](https://github.com/cretinon/shell/)" supporting dockerhub/local repository
* All dockerfiles supports multiarch (linux/arm/v7,linux/arm64/v8,linux/amd64) and multi distribution (debian/alpine)
* Automatic build using CircleCI
* need to find a way to add "FLAGS" in container_start and container_shell (expl vpn flags --mount source=$(OPSYS)_$(SVCNAME),target=/vpn/ --cap-add=NET_ADMIN --device /dev/net/tun... may be in labels like we've done for version)
* ...

#
[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/PJuzGhtpJT1B6rC5YF9SLA/DxRP5jsrcfQSALPEzE5Khu/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/circleci/PJuzGhtpJT1B6rC5YF9SLA/DxRP5jsrcfQSALPEzE5Khu/tree/main) [![codecov](https://codecov.io/github/cretinon/docker/graph/badge.svg?token=UA7LOCR0BN)](https://codecov.io/github/cretinon/docker)
