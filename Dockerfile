# Builder Stage 1: eth2-testnet-genesis
FROM golang:1.23 as builder1
RUN git clone https://github.com/d3athgr1p/eth2-testnet-genesis.git \
    && cd eth2-testnet-genesis \
    && go install . 

# Builder Stage 2: eth2-val-tools
FROM golang:1.23 as builder2
RUN git clone https://github.com/d3athgr1p/eth2-val-tools.git  \
    && cd eth2-val-tools \
    && go install . 

# Builder Stage 3: zcli
FROM golang:1.23 as builder3
RUN git clone https://github.com/d3athgr1p/zcli.git  \
    && cd zcli \
    && go install . 

# Final Stage
FROM debian:latest
WORKDIR /work
VOLUME ["/config", "/data"]
EXPOSE 8000/tcp
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ca-certificates build-essential python3 python3-dev python3-pip gettext-base jq wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY apps /apps
RUN cd /apps/el-gen && pip3 install --break-system-packages -r requirements.txt
COPY --from=builder1 /go/bin/eth2-testnet-genesis /usr/local/bin/
COPY --from=builder2 /go/bin/eth2-val-tools /usr/local/bin/
COPY --from=builder3 /go/bin/zcli /usr/local/bin/
COPY config-example /config
COPY entrypoint.sh .
ENTRYPOINT ["/work/entrypoint.sh"]
