ARG VERSION=5.6.1

FROM ubuntu:20.04 as base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && \
    apt install -y --no-install-recommends cmake git wget curl make ca-certificates bison flex clang perl python3 libxml2-dev cppcheck && \
    apt clean && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 && \
    rm -rf /var/lib/apt/lists/*

# Modified by Thor K. Høgås to utilise 6.0pre6
MAINTAINER Rudolf Hornig <rudi@omnetpp.org>

# first stage - build omnet
FROM base as builder
ARG VERSION
WORKDIR /root
RUN wget https://github.com/omnetpp/omnetpp/releases/download/omnetpp-$VERSION/omnetpp-$VERSION-src-core.tgz \
         --referer=https://omnetpp.org/ -O omnetpp-src-core.tgz --progress=dot:giga && \
         tar xf omnetpp-src-core.tgz && rm omnetpp-src-core.tgz
RUN mv omnetpp-$VERSION omnetpp
WORKDIR /root/omnetpp
ENV PATH /root/omnetpp/bin:$PATH
# remove unused files and build
RUN ./configure WITH_QTENV=no WITH_OSG=no WITH_OSGEARTH=no && \
    make -j $(nproc) MODE=release base && \
    rm -r doc out test samples misc config.log config.status

# second stage - copy only the final binaries (to get rid of the 'out' folder and reduce the image size)
FROM base
ARG VERSION
RUN mkdir -p /root/omnetpp
WORKDIR /root/omnetpp
COPY --from=builder /root/omnetpp/ .
ENV PATH /root/omnetpp/bin:$PATH
RUN chmod 775 /root/ && \
    mkdir -p /root/models && \
    chmod 775 /root/models
WORKDIR /root/models
RUN echo "PS1='omnetpp-$VERSION:\w\$ '" >> /root/.bashrc && chmod +x /root/.bashrc && \
    touch /root/.hushlogin
ENV HOME=/root/
CMD /bin/bash --init-file /root/.bashrc