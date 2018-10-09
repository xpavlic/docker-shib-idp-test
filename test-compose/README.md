The test-compose directory contains an example Shibboleth IdP environment that starts up the IdP, along with an LDAP directory. This example demonstrates how one might go about customizing and deploying their own local IdP containers, using the TIER Shibboleth IdP image as a base image.

In this example, the following cases are covered by this example:

ldap - The IdP uses an LDAP example directory as both the authentication source and attribute source.

It should be noted that while this example uses Docker Compose as a build and deployment vehicle, ideally one should use a CI server to build and publish institution specific images to an image repository as changes to the institution's customizations are committed to the source repository. These images would then be deployed to Docker Swarm, assuming that the appropriate Docker Secrets and Configs have been published to the swarm.


