ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ARG WITH_OPTIONAL_TOOLS=false

RUN cd /bin && ln -sf bash sh

COPY install-verilator.sh /tmp/install-verilator.sh
COPY setup-tools.sh /tmp/setup-tools.sh

WORKDIR /tmp
RUN apt-get update && apt-get install sudo -y \
    && WITH_OPTIONAL_TOOLS=${WITH_OPTIONAL_TOOLS} bash /tmp/setup-tools.sh \
    && cp /tmp/verilator/ci/docker/run/verilator-wrap.sh /usr/local/bin/ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/verilator

CMD [ "/bin/bash" ]
