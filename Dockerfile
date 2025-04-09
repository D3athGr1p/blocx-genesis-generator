FROM golang:1.22 as builder
RUN git clone https://github.com/d3athgr1p/eth2-testnet-genesis.git  \
    && cd eth2-testnet-genesis \
    && go install .
WORKDIR / 
RUN git clone https://github.com/d3athgr1p/eth2-val-tools.git  \
    && cd eth2-val-tools \
    && go install . 
WORKDIR / 
RUN git clone https://github.com/d3athgr1p/zcli.git  \
    && cd zcli \
    && go install . 

FROM debian:latest
WORKDIR /work
VOLUME ["/config", "/data"]
EXPOSE 8000/tcp
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ca-certificates build-essential python3 python3-dev python3.11-venv python3-venv python3-pip gettext-base jq wget curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY apps /apps

ENV PATH="/root/.cargo/bin:${PATH}"
RUN cd /apps/el-gen && python3 -m venv .venv && /apps/el-gen/.venv/bin/pip3 install -r /apps/el-gen/requirements.txt
COPY --from=builder /go/bin/eth2-testnet-genesis /usr/local/bin/eth2-testnet-genesis
COPY --from=builder /go/bin/eth2-val-tools /usr/local/bin/eth2-val-tools
COPY --from=builder /go/bin/zcli /usr/local/bin/zcli
COPY config-example /config
COPY defaults /defaults
COPY entrypoint.sh .
ENTRYPOINT [ "/work/entrypoint.sh" ]