FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    curl unzip build-essential git tar clang

RUN curl -LO https://github.com/odin-lang/Odin/releases/download/dev-2025-04/odin-ubuntu-amd64-dev-2025-04.zip 

RUN unzip odin-ubuntu-amd64-dev-2025-04.zip -d /opt/odin && \
    tar xvzf /opt/odin/dist.tar.gz -C /opt/odin && \ 
    rm odin-ubuntu-amd64-dev-2025-04.zip && \
    rm /opt/odin/dist.tar.gz  
    # ln -s /opt/odin/odin /usr/local/bin/odin

ENV PATH="/opt/odin:${PATH}"

