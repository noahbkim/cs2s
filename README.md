# cs2s

This repository serves as a CS2 server mod development environment.
It provides a `Dockerfile` and setup script for managing an Ubuntu container with `SteamCMD` and `CS2` preinstalled.

## Setup

In order to use `cs2s` you will need the following.

1. Docker
2. Any Steam account credentials

To get started, build the included Docker image.
This creates an Ubuntu 20.04 LTS with a whole host of packages including:

- Developer tools
- CS2 dependencies
- Metamod dependencies
- SteamCMD

You can spin up a container from this image by running:

```bash
docker compose up --detach  # or -d

# Open a TTY (bash is installed if you prefer)
docker compose exec cs2s zsh
```

## Use

Once you've started your container, you'll want to install CS2.
It'll be installed in a persistent volume that can be reused across containers:

```bash
# Run the installation script
cs2s-install
```

You can then use `cs2s-overlay` to create and run overlays of your CS2 installation.
This allows you to simulate having multiple independently-writable copies of the game via OverlayFS. 

```bash
# Create /home/steam/my-overlay
cs2s-overlay add my-overlay

# Editing files only affects the overlay
touch /home/steam/my-overlay/game/csgo/cfg/autoexec.cfg

# Confirm by checking the original installation
ls /cs2/game/csgo/cfg/

# You can see changes in the mounted "upper" directory
ls /home/steam/.overlay/test/upper/game/csgo/cfg

# To run the server in the overlay, you can either `su steam` etc. or use the shorthand
cs2s-overlay start my-overlay +de_dust2
```
