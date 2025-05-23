FROM archlinux:latest

RUN pacman -Sy && pacman -S archlinux-keyring --noconfirm && pacman-key --init && pacman-key --populate 
RUN pacman -Syu --noconfirm

RUN pacman -S odin --noconfirm
RUN pacman -S wayland --noconfirm
RUN pacman -S libegl --noconfirm
RUN pacman -S libxkbcommon --noconfirm

# Install libschrift
RUN pacman -S git base-devel --noconfirm 
RUN cd / && git clone https://github.com/tomolt/libschrift --depth 1 && cd libschrift && make install

# Install resvg
RUN pacman -S cargo wget --noconfirm
RUN cd / && wget https://github.com/linebender/resvg/releases/download/v0.45.1/resvg-0.45.1.tar.xz && \
    tar -xf resvg-0.45.1.tar.xz && \
    cd resvg-0.45.1  && \
    cargo build --release --all && \
    mv target/release/libresvg.a /usr/lib
