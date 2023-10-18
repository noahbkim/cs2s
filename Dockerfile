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
        cmake \
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
        libc6-dev-i386

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
VOLUME ["/work"]

# Expose CS2 ports: https://developer.valvesoftware.com/wiki/Source_Dedicated_Server
EXPOSE 27015/tcp
EXPOSE 27015/udp
EXPOSE 27020/udp
EXPOSE 27005/udp
EXPOSE 26900/udp

# Scripts and configuration
RUN apt install -y zsh ripgrep fd-find
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && yes | ~/.fzf/install
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN sed -i 's/^plugins=.*/plugins=(git fzf dirhistory)/' /root/.zshrc
RUN sed -i 's/^ZSH_THEME=.*/ZSH_THEME="cs2s"/' /root/.zshrc
COPY cs2s.zsh-theme /root/.oh-my-zsh/themes
RUN sed -i 's/\r$//' /root/.oh-my-zsh/themes/cs2s.zsh-theme

# Create a Steam user and run `steamcmd` once to update
RUN adduser --disabled-password --gecos "" steam
RUN su steam -c "steamcmd +quit"

# This would install CS2 into the actual image but I can't get it to work
# RUN --mount=type=secret,id=steamlogin,dst=/home/steam/.steamlogin,required=true,mode=0444 \
#     su steam -c "steamcmd '+force_install_dir /home/steam +runscript /home/steam/.steamlogin +app_update 730 validate +quit'"
