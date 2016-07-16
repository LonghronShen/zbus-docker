FROM buildpack-deps:jessie-curl

# A few problems with compiling Java from source:
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#       really hairy.

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
		git \
		bsdmainutils \
		coreutils \
	&& rm -rf /var/lib/apt/lists/*

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64/jre

ENV JAVA_VERSION 7u101
ENV JAVA_DEBIAN_VERSION 7u101-2.6.6-2~deb8u1

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		openjdk-7-jre-headless="$JAVA_DEBIAN_VERSION" \
	&& rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

# If you're reading this and have any feedback on how this image could be
#   improved, please open an issue or a pull request so we can discuss it!

WORKDIR /app
RUN git clone https://git.oschina.net/rushmore/zbus.git
WORKDIR /app/zbus/zbus-dist/bin
RUN cat zbus.sh | col -b > zbus2.sh && cat tracker.sh | col -b > tracker2.sh
RUN sed 's:#/usr/bin:#!/usr/bin/env bash:g' <zbus2.sh >zbus3.sh && sed 's:#/usr/bin:#!/usr/bin/env bash:g' <tracker2.sh >tracker3.sh
RUN chmod a+x zbus3.sh && chmod a+x tracker3.sh
RUN rm zbus.sh && zbus2.sh && tracker.sh && tracker2.sh && mv zbus3.sh zbus.sh && mv tracker3.sh tracker.sh
ENTRYPOINT ["./zbus.sh"]