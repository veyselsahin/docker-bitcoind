FROM ubuntu:latest as builder

RUN apt update \
    && apt install -y --no-install-recommends \
        ca-certificates \
        wget \
        gnupg \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG VERSION=0.21.0
ARG ARCH=x86_64
ARG BITCOIN_CORE_SIGNATURE=01EA5486DE18A882D4C2684590C8019E36C2E964

RUN cd /tmp \
    && wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS.asc \
    && gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${BITCOIN_CORE_SIGNATURE} \
    && gpg --verify SHA256SUMS.asc \
    && grep bitcoin-${VERSION}-${ARCH}-linux-gnu.tar.gz SHA256SUMS.asc > SHA25SUM \
    && wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/bitcoin-${VERSION}-${ARCH}-linux-gnu.tar.gz \
    && sha256sum -c SHA25SUM \
    && tar -xzvf bitcoin-${VERSION}-${ARCH}-linux-gnu.tar.gz -C /opt \
    && ln -sv bitcoin-${VERSION} /opt/bitcoin

FROM ubuntu:latest

ENV HOME /bitcoin
WORKDIR /bitcoin
EXPOSE 8332 8333

ARG GROUP_ID=1000
ARG USER_ID=1000
RUN groupadd -g ${GROUP_ID} bitcoin \
    && useradd -u ${USER_ID} -g bitcoin -d /bitcoin bitcoin

COPY --from=builder /opt/ /opt/

RUN apt update \
    && apt install -y --no-install-recommends gosu \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && ln -sv /opt/bitcoin/bin/* /usr/local/bin
COPY ./docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["-conf=/opt/bitcoin/bin/bitcoin.conf", "-printtoconsole"]
