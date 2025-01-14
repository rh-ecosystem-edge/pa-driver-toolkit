ARG BASEIMAGE=registry.redhat.io/ubi9/ubi:9.5
FROM ${BASEIMAGE}
ARG VENDOR=''
LABEL vendor=${VENDOR}
LABEL org.opencontainers.image.vendor=${VENDOR}
ARG KERNEL_VERSION='5.14.0-503.21.1.el9_5'
ARG ENABLE_RT=''
USER root

# kernel packages needed to build drivers / kmods 
RUN dnf config-manager --best --setopt=install_weak_deps=False --save

RUN dnf -y install \
    kernel-devel${KERNEL_VERSION:+-}${KERNEL_VERSION} \
    kernel-devel-matched${KERNEL_VERSION:+-}${KERNEL_VERSION} \
    kernel-headers${KERNEL_VERSION:+-}${KERNEL_VERSION} \
    kernel-modules${KERNEL_VERSION:+-}${KERNEL_VERSION} \
    kernel-modules-extra${KERNEL_VERSION:+-}${KERNEL_VERSION} \
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
