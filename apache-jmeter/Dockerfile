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

# Get gnupg for get-product-bits.sh
RUN apk --no-cache --update add gnupg

# Get public signing keys for Apache JMeter
COPY ["keys.gpg", "/tmp"]

# Download the product bits
COPY --from=common ["/opt/get-product-bits.sh","/opt/get-product-bits.sh"]
RUN /opt/get-product-bits.sh --product ${PRODUCT} --version ${VERSION} \
    && unzip -q /tmp/product.zip \
        -d /tmp \
        -x *.bat \
        -x *.dll \
        -x *.exe \
        -x *.ini \
        -x */printable_docs/* \
        -x */docs/* \
   && mv /tmp/${PRODUCT}-${VERSION} /opt/server

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

#-- Ping product name
    PING_PRODUCT="Apache-JMeter" \

#-- Percentage of the container memory to allocate to PingFederate JVM
#-- DO NOT set to 100% or your JVM will exit with OutOfMemory errors and the container will terminate
    JAVA_RAM_PERCENTAGE=90.0 \

#-- The command that the entrypoint will execute in the foreground to
#-- instantiate the container
    STARTUP_COMMAND="${SERVER_ROOT_DIR}/bin/run.sh"

# the method by which the framework can assess whether the container is viable or not
HEALTHCHECK --interval=31s --timeout=29s --start-period=241s --retries=7 CMD [ "liveness.sh" ]

LABEL name="${PING_PRODUCT}" \
      version="${IMAGE_VERSION}" \
      release="${IMAGE_GIT_REV}" \
      date="${DATE}" \
      summary="Apache JMeter can send HTTPS requests to any given PingFederate server" \
      description="Apache JMeter can send HTTPS requests to any given PingFederate server"
COPY --from=final-staging ["/","/"]
