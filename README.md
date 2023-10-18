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
