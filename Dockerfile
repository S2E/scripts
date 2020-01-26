# Copyright (C) 2017-2020, Cyberhaven
# All rights reserved.
#
# Licensed under the Cyberhaven Research License Agreement.

# Installs S2E and its associated libraries and tools to /opt/s2e

FROM cyberhaven/libs2e-build

COPY .repo /.repo
COPY scripts /scripts
COPY qemu /qemu

RUN cd s2e-build && \
    make -f /scripts/Makefile BUILD_ARCH=x86_64 S2E_PREFIX=/opt/s2e QEMU_SRC=/qemu stamps/qemu-release-install

# Install s2e-env
COPY s2e-env s2e/s2e-env
RUN apt-get -y install python-pip && \
    cd s2e/s2e-env && \
    pip install --process-dependency-links .
