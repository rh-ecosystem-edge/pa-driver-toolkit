#ARG BASEIMAGE="quay.io/centos/centos:stream9"
ARG BASEIMAGE="registry.access.redhat.com/ubi9/ubi:9.5"

FROM ${BASEIMAGE}

ARG VENDOR=''
LABEL vendor=${VENDOR}
LABEL org.opencontainers.image.vendor=${VENDOR}

ARG KERNEL_VERSION='5.14.0-503.15.1.el9_5'
ARG ENABLE_RT=''

USER root

RUN if test -z "${KERNEL_VERSION}" ; then \
      echo "The KERNEL_VERSION argument is mandatory. Exiting" ; \
      exit 1 ; \
    fi \
    && echo "Kernel version: ${KERNEL_VERSION}" \
    && dnf -y install dnf-plugin-config-manager \
    && dnf config-manager --best --nodocs --setopt=install_weak_deps=False --save \
    && dnf -y update --exclude kernel* \
    && dnf -y install \
        kernel-${KERNEL_VERSION} \
        kernel-devel-${KERNEL_VERSION} \
        kernel-modules-${KERNEL_VERSION} \
        kernel-modules-extra-${KERNEL_VERSION} \
    && if [ "${ENABLE_RT}" ] && [ $(arch) == "x86_64" ]; then \
        dnf -y --enablerepo=rt install \
            kernel-rt-${KERNEL_VERSION} \
            kernel-rt-devel-${KERNEL_VERSION} \
            kernel-rt-modules-${KERNEL_VERSION} \
            kernel-rt-modules-extra-${KERNEL_VERSION}; \
    fi \
    && export INSTALLED_KERNEL=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-core-${KERNEL_VERSION}) \
    && export GCC_VERSION=$(cat /lib/modules/${INSTALLED_KERNEL}/config | grep -Eo "gcc \(GCC\) ([0-9\.]+)" | grep -Eo "([0-9\.]+)") \
    && dnf -y install \
        binutils \
        diffutils \
        elfutils-libelf-devel \
        jq \
        kabi-dw kernel-abi-stablelists \
        keyutils \
        kmod \
        gcc-${GCC_VERSION} \
        git \
        make \
        mokutil \
        openssl \
        pinentry \
        rpm-build \
        xz \
    && dnf -y clean all \
    && rm -rf /var/cache/yum \
    && useradd -u 1001 -m -s /bin/bash builder

# Last layer for metadata for mapping the driver-toolkit to a specific kernel version
RUN if [ "${KERNEL_VERSION}" == "" ]; then \
        export INSTALLED_KERNEL=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-core); \
    else \
        export INSTALLED_KERNEL=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-core-${KERNEL_VERSION}) ;\
    fi \
    && echo "{ \"KERNEL_VERSION\": \"${INSTALLED_KERNEL}\" }" > /etc/driver-toolkit-release.json \
    && echo -e "KERNEL_VERSION=\"${INSTALLED_KERNEL}\"" > /etc/driver-toolkit-release.sh

USER builder
