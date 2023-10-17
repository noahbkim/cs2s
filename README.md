# cs2s

This repository serves as a CS2 server mod development environment.
It provides a `Dockerfile` and setup script for managing an Ubuntu container with `SteamCMD` and `CS2` preinstalled.

## Setup

In order to use `cs2s` you will need the following.

1. Docker
2. A Steam account
3. A recent Python 3

Because there is currently no dedicated server, you must provide a steam account to download the client version of CS2.
This is facilitated by `--secret id=steamlogin`, which expects a newline-delimited series of `SteamCMD` commands that will authenticate you.
I recommend putting the following in `docker/.steamlogin`, which is already in the `.gitignore`:

```
login <username> <password> <2fa>
```

You can then run the following command to build the image:
**Warning**: the resulting image will be at least as large as a CS2 client installation (on the order of 50-60 GB).
Make sure you've configured Docker to store the image somewhere with plenty of storage.
Also be sure to prune unused images regularly (naming the images, which is handled by `docker.py`, avoids this).

```
# From the root of this repository
$ python3 docker.py build
```

## Use

I've included a Python script that automatically manages a container of the constructed image.
Use it as follows.
Note that if you have not run the build step described above, the management script will build the image in a subprocess.
Currently, the subprocess does not pipe its output back to the shell, so you will not be able to see progress. 

```
# Start a container with our image and open a shell in it
$ python3 docker.py shell

# Kill the container
$ python3 docker.py stop
```
