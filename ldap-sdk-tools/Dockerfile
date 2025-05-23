#- # Ping Identity Docker Image - `ldap-sdk-tools`
#-
#- This docker image provides an alpine image with the LDAP Client
#- SDK tools to be used against other PingDirectory instances.
#-
#- ## Related Docker Images
#- - `openjdk:8-jre8-alpine` - Alpine server to run LDAP SDK Tools from
#-

#################################################################################

# Top level ARGS used in all FROM commands
ARG ARCH
ARG DEPS
ARG GIT_TAG
ARG JVM
ARG LATEST_ALPINE_VERSION
ARG REGISTRY
ARG SHIM
ARG SHIM_TAG

#################################################################################

FROM pingcommon-rebased:local as common
FROM pingjvm-shim-rebased:local as jvm

#################################################################################

# Always use alpine to download product bits
FROM cgr.dev/chainguard/jre:latest-dev as product-staging

# ARGS used in get-product-bits.sh RUN command
ARG PRODUCT
ARG VERSION
ARG ARTIFACTORY_URL
ARG VERBOSE

#Add wait-for
COPY ["wait-for","/opt/"]

# Download the product bits
COPY --from=common ["/opt/get-product-bits.sh","/opt/get-product-bits.sh"]
RUN /opt/get-product-bits.sh --product ${PRODUCT} --version ${VERSION} \
    && unzip -q /tmp/product.zip -d /tmp/ \
        -x *.bat \
        -x *.dll \
        -x *.exe \
        -x *.ini \
        -x */src.zip \
        -x */android-ldap-client/* \
        -x */docs/* \
    && mv /tmp/unboundid-ldapsdk-*/tools /opt/ \
    && mv /tmp/unboundid-ldapsdk-*/LICENSE* /opt/ \
    && mv /tmp/unboundid-ldapsdk-*/unboundid-ldapsdk.jar /opt/

#################################################################################

FROM pingjvm-shim-rebased:local as final-staging

# get the product bits FIRST
COPY --from=product-staging ["/opt/","/opt/"]

# get Ping-wide common scripts
#   this needs to happen after the bits have been laid down
#   so they can be patched
COPY --from=common ["/opt/","/opt/"]

# get the jvm
COPY --from=jvm ["/opt/java","/opt/java"]

# apply product-specific hooks and patches
COPY ["/opt","/opt"]

# add legal information in licenses directory
COPY --from=product-staging ["/opt/LICENSE.txt","/licenses/LDAPSDK-LICENSE-short.txt"]
COPY --from=product-staging ["/opt/LICENSE-UnboundID-LDAPSDK.txt","/licenses/"]
COPY --from=product-staging ["/opt/LICENSE-GPLv2.txt","/licenses/"]
COPY --from=product-staging ["/opt/LICENSE-LGPLv2.1.txt","/licenses/"]

# Run build
RUN ["/opt/build.sh"]

#################################################################################

# the final image
FROM pingbase-rebased:local
# Image version and git revision, set by build process of the docker build
ARG IMAGE_VERSION="undefined"
ARG IMAGE_GIT_REV=""
ARG DATE
ARG VERSION
ENV SHIM=${SHIM} \
    IMAGE_VERSION=${IMAGE_VERSION} \
    IMAGE_GIT_REV=${IMAGE_GIT_REV} \
    DATE=${DATE} \
    PING_PRODUCT_VERSION=${VERSION} \
    PATH=/opt/tools:${PATH} \
#-- Ping product name
    PING_PRODUCT="ldap-sdk-tools"

# the method by which the framework can assess whether the container is viable or not
HEALTHCHECK --interval=31s --timeout=29s --start-period=241s --retries=7 CMD [ "liveness.sh" ]

LABEL name="${PING_PRODUCT}" \
      version="${IMAGE_VERSION}" \
      release="${IMAGE_GIT_REV}" \
      date="${DATE}" \
      summary="ldap-sdk-tools provides LDAP Client SDK tools to be used against other PingDirectory instances." \
      description="ldap-sdk-tools provides LDAP Client SDK tools to be used against other PingDirectory instances." \
      license="Apache License v2.0, GPLv2, LGPLv2.1, Ping Identity UnboundID LDAP SDK Free Use"

VOLUME ["/opt/out"]
COPY --from=final-staging ["/","/"]

#- ## List all available tools
#- `docker run -it --rm pingidentity/ldap-sdk-tools:edge ls`
#-
#- ## Use LDAPSearch
#- ### Get some help
#- `docker run -it --rm pingidentity/ldap-sdk-tools:edge ldapsearch --help`
#-
#- ### Simple search
#- ```Bash
#- docker run -it --rm pingidentity/ldap-sdk-tools:edge \
#-     ldapsearch \
#-         -b dc=example,dc=com \
#-         -p 1389 "(objectClass=*)"
#- ```
#-
#- ### Save output to host file
#- ```Bash
#- docker run -it --rm \
#-     -v /tmp:/opt/out \
#-     pingidentity/ldap-sdk-tools:edge \
#-     ldapsearch \
#-         --baseDN dc=example,dc=com \
#-         --port 1389 \
#-         --outputFormat json "(objectClass=*)" >/tmp/search-result.json
#- ```
#-
#- ## Use manage-certificates
#- ### trusting certificates
#- ```Bash
#- PWD=2FederateM0re
#- mkdir -p /tmp/hibp
#- docker run -it --rm \
#-   -v /tmp/hibp:/opt/out \
#-   pingidentity/ldap-sdk-tools:edge \
#-   manage-certificates trust-server-certificate \
#-     --hostname haveibeenpwned.com \
#-     --port 1443 \
#-     --keystore /opt/out/hibp-2019.jks \
#-     --keystore-password ${PWD}
#- ls -all /tmp/hibp
#- keytool -list \
#-   -keystore /tmp/hibp/hibp-2019.jks \
#-   -storepass ${PWD}
#- ```
