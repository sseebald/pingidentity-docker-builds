#- # Ping Identity DevOps Docker Image - `pingdatasync`
#-
#- This docker image includes the Ping Identity PingDataSync product binaries
#- and associated hook scripts to create and run a PingDataSync instance.
#-
#- ## Related Docker Images
#- - `pingidentity/pingbase` - Parent Image
#- > This image inherits, and can use, Environment Variables from [pingidentity/pingbase](https://devops.pingidentity.com/docker-images/pingbase/)
#- - `pingidentity/pingdatacommon` - Common Ping files (i.e. hook scripts)
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

FROM pingdatacommon-rebased:local as common
FROM pingjvm-shim-rebased:local as jvm

#################################################################################

# Always use alpine to download product bits
FROM cgr.dev/chainguard/jre:latest-dev as product-staging

# ARGS used in get-product-bits.sh RUN command
ARG ARTIFACTORY_URL
ARG PRODUCT
ARG SNAPSHOT_URL
ARG VERBOSE
ARG VERSION

# Get libxml2-utils for get-product-bits.sh
RUN apk --no-cache --update add libxml2-utils

# Get local filesystem product bits if present
COPY ["tmp/", "/tmp/"]

# Download the product bits
COPY --from=common ["/opt/get-product-bits.sh","/opt/get-product-bits.sh"]
RUN /opt/get-product-bits.sh --product ${PRODUCT} --version ${VERSION} \
    && unzip -q /tmp/product.zip -d /tmp/ \
    && mv /tmp/PingDataSync /opt/server

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
COPY --from=product-staging ["/opt/server/legal/","/licenses/"]

# Run build
RUN ["/opt/build.sh"]

#################################################################################

# The final image
FROM pingbase-rebased:local
# Image version and git revision, set by build process of the docker build
ARG IMAGE_VERSION="undefined"
ARG IMAGE_GIT_REV=""
ARG DATE
ARG VERSION
# PingIdentity license version
ARG LICENSE_VERSION

ENV SHIM=${SHIM} \
    IMAGE_VERSION=${IMAGE_VERSION} \
    IMAGE_GIT_REV=${IMAGE_GIT_REV} \
    DATE=${DATE} \
    PING_PRODUCT_VERSION=${VERSION} \
#-- Files tailed once container has started
    TAIL_LOG_FILES="${SERVER_ROOT_DIR}/logs/sync" \
#-- PD License directory. This value is set from the pingbase docker file
    LICENSE_DIR="${PD_LICENSE_DIR}" \
#-- Name of license file
    LICENSE_FILE_NAME="PingDirectory.lic" \
#-- Short name used when retrieving license from License Server
    LICENSE_SHORT_NAME=PD \
#-- Version used when retrieving license from License Server
    LICENSE_VERSION=${LICENSE_VERSION} \
#-- Ping product name
    PING_PRODUCT=PingDataSync \
#-- The command that the entrypoint will execute in the foreground to
#-- instantiate the container
    STARTUP_COMMAND="${SERVER_ROOT_DIR}/bin/start-server" \
#-- The command-line options to provide to the the startup command when
#-- the container starts with the server in the foreground. This is the
#-- normal start flow for the container
    STARTUP_FOREGROUND_OPTS="--nodetach" \

#-- The default retry timeout in seconds for manage-topology and
#-- remove-defunct-server
    RETRY_TIMEOUT_SECONDS=180 \

#-- Failover administrative user
    ADMIN_USER_NAME=admin \

#-- Location of file with the root user password (i.e. cn=directory manager).
#-- Defaults to /SECRETS_DIR/root-user-password
    ROOT_USER_PASSWORD_FILE= \
#-- Location of file with the admin password, used as the password replication admin
#-- Defaults to /SECRETS_DIR/admin-user-password
    ADMIN_USER_PASSWORD_FILE= \

#-- Location of the keystore file containing the server certificate.
#-- If left undefined, the SECRETS_DIR will be checked for a keystore.
#-- If that keystore does not exist, the server will generate a self-signed certificate.
    KEYSTORE_FILE= \
#-- Location of the pin file for the keystore defined in KEYSTORE_FILE.
#-- You must specify a KEYSTORE_PIN_FILE when a KEYSTORE_FILE is present.
#-- This value does not need to be defined when allowing the server to generate a
#-- self-signed certificate.
    KEYSTORE_PIN_FILE= \
#-- Format of the keystore defined in KEYSTORE_FILE. One of "jks", "pkcs12",
#-- "pem", or "bcfks" (in FIPS mode). If not defined, the keystore format will
#-- be inferred based on the file extension of the KEYSTORE_FILE, defaulting to "jks".
    KEYSTORE_TYPE= \
#-- Location of the truststore file for the server.
#-- If left undefined, the SECRETS_DIR will be checked for a truststore.
#-- If that truststore does not exist, the server will generate a truststore, containing
#-- its own certificate.
    TRUSTSTORE_FILE= \
#-- Location of the pin file for the truststore defined in TRUSTSTORE_FILE.
#-- You must specify a TRUSTSTORE_PIN_FILE when a TRUSTSTORE_FILE is present.
#-- This value does not need to be defined when allowing the server to generate a truststore.
    TRUSTSTORE_PIN_FILE= \
#-- Format of the truststore defined in TRUSTSTORE_FILE. One of "jks", "pkcs12",
#-- "pem", or "bcfks" (in FIPS mode). If not defined, the truststore format will
#-- be inferred based on the file extension of the TRUSTSTORE_FILE, defaulting to "jks".
    TRUSTSTORE_TYPE= \

#-- Directory for the profile used by the PingData manage-profile tool
    PD_PROFILE="${STAGING_DIR}/pd.profile" \

#-- Setting this variable to true speeds up server startup time by
#-- skipping an unnecessary JVM check.
    UNBOUNDID_SKIP_START_PRECHECK_NODETACH=true \

#-- Whether this container is running as a Pod in a Kubernetes StatefulSet, and
#-- that StatefulSet is using the Parallel podManagementPolicy. This property allows
#-- for starting up Pods in parallel to speed up the initial startup of PingDataSync
#-- topologies. This variable must be set to true when using the Parallel podManagementPolicy.
#-- Note: when using parallel startup, ensure the RETRY_TIMEOUT_SECONDS variable is
#-- large enough. The pods will be enabling replication simultaneously, so some pods
#-- will have to retry while waiting for others to complete. If the timeout is too low,
#-- a Pod may end up restarting unnecessarily.
    PARALLEL_POD_MANAGEMENT_POLICY=false \

#-- Set to true to skip the waiting for DNS step that is normally done just before
#-- attempting to join the topology.
    SKIP_WAIT_FOR_DNS=false \

#-- There is an additional certificate-based variable used to identity the certificate alias 
#-- used within the `KEYSTORE_FILE`. That variable is called `CERTIFICATE_NICKNAME`,
#-- which identifies the certificate to use by the server in the `KEYSTORE_FILE`. 
#-- If a value is not provided, the container will look at the list certs found in the 
#-- `KEYSTORE_FILE` and if one - and only one - certificate is found of type `PrivateKeyEntry`,
#-- that alias will be used.
    CERTIFICATE_NICKNAME= \

#-- Sets the number of columns in PingDataSync command-line tool output
    COLUMNS=120 \

#-- Force a rebuild (replace-profile) of PingDataSync on restart.
#-- Used to ensure that the server configuration exactly matches the server profile.
#-- This variable will slow down startup times and should only be used
#-- when necessary.
    PD_REBUILD_ON_RESTART=false

# the method by which the framework can assess whether the container is viable or not
HEALTHCHECK --interval=31s --timeout=29s --start-period=241s --retries=7 CMD [ "liveness.sh" ]

LABEL name="${PING_PRODUCT}" \
      version="${IMAGE_VERSION}" \
      release="${IMAGE_GIT_REV}" \
      date="${DATE}" \
      summary="The PingDataSync server is an efficient, Java-based server that provides high throughput, low latency, and bidirectional real-time synchronization between two endpoint topologies, such as PingDirectory servers, PingDirectoryProxy servers, PingOne, or relational database management systems (RDBMS) systems." \
      description="PingDataSync uses a dataless approach that synchronizes changes directly from the data sources in the background so that applications can continue to update their data sources directly. PingDataSync doesn't store any data from the endpoints themselves, which reduces hardware and administration costs. The server's high-availability mechanisms allow for easy failover from the main PingDataSync server to redundant instances."

EXPOSE ${LDAP_PORT} ${LDAPS_PORT} ${HTTPS_PORT} ${JMX_PORT}

COPY --from=final-staging ["/","/"]

#- ## Running a PingDataSync container
#- ```
#-   docker run \
#-            --name pingdatasync \
#-            --publish 1389:1389 \
#-            --publish 8443:1443 \
#-            --detach \
#-            --env SERVER_PROFILE_URL=https://github.com/pingidentity/pingidentity-server-profiles.git \
#-            --env SERVER_PROFILE_PATH=simple-sync/pingdatasync \
#-            --env PING_IDENTITY_ACCEPT_EULA=YES \
#-            --env PING_IDENTITY_DEVOPS_USER \
#-            --env PING_IDENTITY_DEVOPS_KEY \
#-            --tmpfs /run/secrets \
#-            pingidentity/pingdatasync:edge
#- ```
