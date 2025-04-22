ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

RUN cd /bin && ln -sf bash sh

RUN apt update
RUN apt install sudo -y
RUN apt clean

COPY install-verilator.sh /tmp/install-verilator.sh
COPY setup-tools.sh /tmp/setup-tools.sh
RUN cd /tmp && bash ./setup-tools.sh

CMD [ "/bin/bash" ]
