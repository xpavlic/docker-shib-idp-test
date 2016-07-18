FROM bigfleet/centos7base

# Establish a default value for critical variables
# These values are not used by bin scripts or the pipeline.
# Those values are set in common.bash
ARG registry=docker.io
ARG maintainer=tier
ARG imagename=shibboleth_idp
ARG version=3.2.1

ENV VERSION=$version

MAINTAINER $maintainer
LABEL Vendor="Internet2"
LABEL ImageType="Shibboleth IDP Release"
LABEL ImageName=$imagename
LABEL ImageOS=centos7
LABEL Version=$VERSION

CMD echo $VERSION