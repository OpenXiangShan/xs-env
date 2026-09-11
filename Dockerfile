ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ARG SLIM=false

RUN cd /bin && ln -sf bash sh
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries

WORKDIR /tmp
COPY setup-tools.sh /tmp/setup-tools.sh

# do not use bash /tmp/setup-tools.sh --target all,
# to split the whole installation into multiple layers,
# so that the cache can be reused for each layer

COPY install-scripts/base.sh /tmp/install-scripts/base.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/setup-tools.sh --target base

COPY install-scripts/llvm.sh /tmp/install-scripts/llvm.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/setup-tools.sh --target llvm
ENV PATH="/usr/lib/llvm-19/bin:${PATH}"

COPY install-scripts/jdk.sh /tmp/install-scripts/jdk.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/setup-tools.sh --target jdk
ENV PATH="/opt/graalvm-jdk-21/bin:${PATH}"
ENV JAVA_HOME="/opt/graalvm-jdk-21"

COPY install-scripts/mill.sh /tmp/install-scripts/mill.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/setup-tools.sh --target mill

COPY install-scripts/verilator.sh /tmp/install-scripts/verilator.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/setup-tools.sh --target verilator && \
    cp /tmp/verilator/ci/docker/run/verilator-wrap.sh /usr/local/bin/ && \
    rm -rf /tmp/verilator

COPY install-scripts/gsim.sh /tmp/install-scripts/gsim.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/setup-tools.sh --target gsim

COPY install-scripts/optional.sh /tmp/install-scripts/optional.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    if [ "$SLIM" != true ]; then bash /tmp/setup-tools.sh --target optional; fi

ENV LC_ALL="C.UTF-8"
ENV LANG="C.UTF-8"

CMD [ "/bin/bash" ]
