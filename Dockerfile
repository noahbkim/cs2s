FROM ubuntu:mantic

# Scripts and configuration
COPY docker/.bashrc /root/
RUN sed -i 's/\r$//' /root/.bashrc

# Dependencies
RUN apt-get update && apt-get install -y \
    g++ \
    g++-multilib \
    make \
    valgrind \
    gdb \
    software-properties-common \
    cmake \
    curl \
    pkg-config \
    wget \
    lib32stdc++-9-dev \
    lib32z1-dev \
    libc6-i386  \
    libc6-dev-i386

# Python for configuration and deployment
RUN add-apt-repository ppa:deadsnakes/ppa \
    && apt-get install -y \
        python3.11 \
        python3.11-dev \
        python3.11-distutils \
        python3-pip

# Create the dev path to mount
VOLUME ["/work"]
WORKDIR /work
