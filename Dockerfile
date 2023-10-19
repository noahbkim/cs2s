# This file is ordered by how frequently each command is subject to change,
# allowing Docker to cache as many intermediate layers as possible.
FROM ubuntu:focal

# Enable 32-bit dependencies
RUN apt update \
    && apt install -y software-properties-common \
    && add-apt-repository multiverse \
    && add-apt-repository ppa:deadsnakes/ppa \
    && dpkg --add-architecture i386  \
    && apt update

# Developer tools
RUN apt install -y \
        g++ \
        g++-multilib \
        make \
        valgrind \
        gdb \
        curl \
        pkg-config \
        wget \
        git \
        nano

# Metamod
RUN apt install -y \
        lib32stdc++-7-dev \
        lib32z1-dev \
        libc6-i386  \
        libc6-dev-i386 \
        protobuf-compiler

# SteamCMD; note we have to manually accept Steam TOS in advance here
RUN echo steam steam/question select "I AGREE" | debconf-set-selections
RUN echo steam steam/license note '' | debconf-set-selections
RUN apt install -y \
        lib32stdc++6 \
        lib32gcc-s1 \
        steamcmd

# Python for configuration and deployment
RUN apt install -y \
        python3.11 \
        python3.11-dev \
        python3.11-distutils \
        python3-pip

# Create the dev path to mount
VOLUME /work
VOLUME /cs2

# Expose CS2 ports: https://developer.valvesoftware.com/wiki/Source_Dedicated_Server
EXPOSE 27015/tcp
EXPOSE 27015/udp
EXPOSE 27020/udp
EXPOSE 27005/udp
EXPOSE 26900/udp

# Create a Steam user and run `steamcmd` once to update. Also make sure we own
# the volume where we install cs2.
RUN adduser --disabled-password --gecos "" steam
RUN su steam -c "steamcmd +quit"
RUN mkdir -p /cs2 && chown steam:steam /cs2

# Fix a bunch of missing symlinks so SteamCMD actually works. The first one
# fixes a warning in the SteamCMD console. The latter two ensure steamclient.so
# can be accessed by the server runtime.
RUN ln -s /home/steam/.steam/steamcmd/linux32/steamclient.so /home/steam/.steam/steamcmd/steamservice.so \
    && mkdir -p /home/steam/.steam/sdk32 \
    && ln -s /home/steam/.steam/steamcmd/linux32/steamclient.so /home/steam/.steam/sdk32/steamclient.so \
    && mkdir -p /home/steam/.steam/sdk64 \
    && ln -s /home/steam/.steam/steamcmd/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so \
    && chown -R steam:steam /home/steam/.steam

# Install the latest CMake; the Debian package is pretty out of date
RUN pip install cmake

# Install AMBuild
RUN git clone --depth 1 https://github.com/alliedmodders/ambuild ~/.ambuild && pip install ~/.ambuild

# Developer stuff
RUN apt install -y zsh tmux ripgrep fd-find
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && yes | ~/.fzf/install
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN sed -i 's/^plugins=.*/plugins=(git fzf dirhistory)/' /root/.zshrc
RUN sed -i 's/^ZSH_THEME=.*/ZSH_THEME="cs2s"/' /root/.zshrc
COPY cs2s.zsh-theme /root/.oh-my-zsh/themes
RUN sed -i 's/\r$//' /root/.oh-my-zsh/themes/cs2s.zsh-theme
RUN echo "cd /work" >> /root/.zshrc
RUN chsh -s /usr/bin/zsh

# Bin scripts
COPY bin/* /usr/local/bin/
RUN find /usr/local/bin/ -type f | xargs sed -i 's/\r$//'
