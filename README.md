# cs2s

This repository serves as a CS2 server mod development environment.
It provides a `Dockerfile` and setup script for managing an Ubuntu container with `SteamCMD` and `CS2` preinstalled.

## Setup

In order to use `cs2s` you will need the following.

1. Docker
2. Any Steam account credentials
3. A recent Python 3

To get started, build the included Docker image.
This creates an Ubuntu 20.04 LTS with a whole host of packages including SteamCMD, CS2 dependencies, Metamod dependencies, and developer tools.

```
# From the root of this repository
$ python3 docker.py build
```

## Use

Once the image is built, you can start a container.
Please note that the commands for managing the container are rudimentary at best; you may have to delete the lockfile or manage containers and images manually.

```
# Start a container with our image
host $ python3 docker.py start

# Open a shell in the currently running image (will automatically invoke `start` if needed)
host $ python3 docker.py shell
```

Once you've opened a shell in your container, you'll have to install CS2.
You can do this via `SteamCMD` as the `steam` user.

```
container $ su steam
container $ steamcmd
Steam>login <username>
Steam>app_update 730 validate
Steam>quit
```

You'll then be able to run the dedicated server via the following:

```
container $ su steam
container $ ~/.steam/SteamApps/common/Counter-Strike\ Global\ Offensive/game/bin/linuxsteamrt64/cs2 -dedicated +map de_dust2
```

## Advanced Use

Until the management script improves, the following commands will have to suffice.

```
# Kill the container (not typically necessary besides to save resources), will erase CS2 installation
$ python3 docker.py stop

# Manually kill the container
$ docker container ls  # Find your container ID in the output
$ docker container kill <id>

# Manually delete the lockfile to indicate to `docker.py` there's no running container
$ rm .docker
```
