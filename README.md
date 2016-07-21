# Shibboleth IDP Container Images

[![Build Status](https://jenkins.testbed.tier.internet2.edu/buildStatus/icon?job=docker/shib-idp/master)](https://jenkins.testbed.tier.internet2.edu/job/docker/job/shib-idp/job/master/)

This repository creates and distributes Shibboleth IDP images to Dockerhub.

## Supported Images

### Release image

These images track official releases of the software.  The `master` branch produces these images, and the build pipeline distributes the results to Dockerhub.

## Development

### Configuration

To alter project configuration details (e.g. which version of the Shibboleth IDP software is the latest), refer to common.bash-- a file referenced by many places.