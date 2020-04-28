ARG VERSION=5.6.1

FROM ubuntu:20.04 as base
ARG VERSION

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && \
    apt-get install -y --no-install-recommends \
		# OMNeT++ build tools
		make bison flex clang \
		# OMNeT++ requirements
		python3 perl libxml2-dev \
		# zlib headers for < 6.X
		zlib1g-dev \
		# build tools & other tools in addition to OMNeT++ requirements
		ca-certificates wget curl cmake git cppcheck graphviz doxygen && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

LABEL maintainer="Thor K. Høgås <thor@roht.no>"
LABEL org.omnetpp.version="$VERSION"

# First stage: build OMNeT++ from source
FROM base as builder
ARG VERSION

WORKDIR /root
RUN wget https://github.com/omnetpp/omnetpp/releases/download/omnetpp-$VERSION/omnetpp-$VERSION-src-core.tgz \
         --referer=https://omnetpp.org/ \
		 -O omnetpp-src-core.tgz \
		 --progress=dot:giga && \
	 tar xf omnetpp-src-core.tgz && \
	 rm omnetpp-src-core.tgz && \
	 mv omnetpp-$VERSION omnetpp
WORKDIR /root/omnetpp
ENV PATH /root/omnetpp/bin:$PATH
# Do not build QtEnv, OSG or OSGEarth
RUN ./configure WITH_QTENV=no WITH_OSG=no WITH_OSGEARTH=no && \
    make -j $(nproc) MODE=release base && \
    rm -r doc out test samples misc config.log config.status

# Final stage: copy pre-built binaries from builder
FROM base as final
ARG VERSION

ENV PATH /root/omnetpp/bin:$PATH
ENV HOME=/root/

RUN mkdir -p /root/omnetpp /root/models && \
	chmod 775 /root/ /root/models
WORKDIR /root/omnetpp
COPY --from=builder /root/omnetpp/ .
RUN echo "PS1='omnetpp-$VERSION:\w\$ '" >> /root/.bashrc && \
	chmod +x /root/.bashrc && \
    touch /root/.hushlogin
WORKDIR /root/models

CMD /bin/bash
