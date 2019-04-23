FROM golang:1.13.0-stretch

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
ENV GOROOT="/usr/local/go${GOLANG_VERSION}"
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes
#support azure devops convention
RUN cp -R /usr/local/go ${GOROOT}

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  curl \
  jq \
  git \
  iputils-ping \
  libc6 \
  libicu57 \
  libgcc1 \
  libgssapi-krb5-2 \
  libstdc++6 \
  zlib1g \
  zip \
  unzip \
  xz-utils \
  rsync \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://get.docker.com | bash
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | \
  tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ stretch main" | \
  tee /etc/apt/sources.list.d/azure-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends azure-cli



RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian \
  $(lsb_release -cs) \
  stable"
RUN apt-get update && apt-get install -y containerd.io
RUN mkdir -p /etc/containerd && containerd config default > /etc/containerd/config.toml
RUN echo 'runtime-endpoint: unix:///run/containerd/containerd.sock' > /etc/crictl.yaml
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli

# nodejs to run the agent
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node
ENV NODE_VERSION 12.3.1
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
  amd64) ARCH='x64';; \
  ppc64el) ARCH='ppc64le';; \
  s390x) ARCH='s390x';; \
  arm64) ARCH='arm64';; \
  armhf) ARCH='armv7l';; \
  i386) ARCH='x86';; \
  *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
  94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
  FD3A5288F042B6850C66B31F09FE44734EB7990E \
  71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
  DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
  C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  B9AE9905FFD7803F25714661B63B535A4C206CA9 \
  77984A986EBC2AA786BC0F66B01FBB92821C587A \
  8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  4ED778F539E3634C779C87C6D7062848A1AB005C \
  A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
  B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
  gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
  gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
  gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV DOTNET_SDK_VERSION 3.0.100-preview9-014004

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
  && dotnet_sha512='b4e4580250f172c7b14cbce96d2de54d13a0b312ed71f86986cc53a9392491347e83cdefc2805a23bd652fc2cc0658c2e74fc8c05212c3983c19e2adbc1fe9a3' \
  && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
  && mkdir -p /usr/share/dotnet \
  && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
  && rm dotnet.tar.gz \
  && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

ENV ASPNETCORE_URLS=http://+:80 \
  # Enable detection of running in a container
  DOTNET_RUNNING_IN_CONTAINER=true \
  # Enable correct mode for dotnet watch (only mode supported in a container)
  DOTNET_USE_POLLING_FILE_WATCHER=true \
  # Skip extraction of XML docs - generally not useful within an image/container - helps performance
  NUGET_XMLDOC_MODE=skip

RUN sed -i -e's/ssl_conf = ssl_sect/# ssl_conf = ssl_sect/' /etc/ssl/openssl.cnf

WORKDIR /azp

COPY ./start-agent.sh .
COPY ./run.sh .
RUN chmod +x start-agent.sh
RUN chmod +x run.sh

CMD ["./run.sh"]