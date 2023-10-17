from __future__ import annotations

import argparse
import functools
import subprocess
from pathlib import Path

REPOSITORY_PATH = Path(__file__).absolute().parent
CONTAINER_LOCK_PATH = REPOSITORY_PATH / ".docker"


class DockerError(Exception):
    """For emitting errors on the CLI."""


@functools.cache
def check_docker_available() -> None:
    """Check the output of the toplevel docker command."""

    print("Checking Docker is available on the command line")
    process = subprocess.run(
        ("docker",),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if process.returncode != 0:
        raise DockerError(f"Docker is unavailable: {process.stderr}")


def build_docker_image(name: str) -> int:
    """Build the Dockerfile and assign it the given name."""

    print("Building the Docker image")
    process = subprocess.run(
        ("docker", "build", REPOSITORY_PATH, "-t", name, "--secret", "id=steamlogin,src=docker/.steamlogin"),
        shell=True,
    )
    return process.returncode


def start_docker_container(image_id: str) -> str:
    """Invoke `docker run` and return the container ID."""

    print(f"Starting the Docker container from {image_id}")
    process = subprocess.run(
        ("docker", "run", "-v", f"{REPOSITORY_PATH}:/work", "-d", "-t", image_id),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
    )

    if process.returncode != 0:
        raise DockerError(f"Failed to start the Docker container: {process.stderr}")

    container_id = process.stdout.strip()
    return container_id


def open_docker_container_shell(container_id: str) -> int:
    """Shell into the container."""

    print(f"Opening a shell into {container_id}")
    return subprocess.call(("docker", "exec", "-i", "-t", container_id, "bash"), shell=True)


def stop_docker_container(container_id: str) -> None:
    """Call `docker kill` on the given container."""

    print(f"Stopping Docker container {container_id}")
    process = subprocess.run(
        ("docker", "kill", container_id),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if process.returncode != 0:
        raise DockerError(f"Failed to stop the Docker container: {process.stderr}")


def write_container_lockfile(container_id: str) -> None:
    """Write the container ID to a file for use between runs."""

    print(f"Writing {container_id} to {CONTAINER_LOCK_PATH}")
    try:
        CONTAINER_LOCK_PATH.write_text(container_id)
    except OSError as error:
        raise DockerError(f"Failed to write {container_id} to {CONTAINER_LOCK_PATH}: {error}")


def read_container_lockfile() -> str | None:
    """Try to read a container ID from the lockfile."""

    print(f"Reading {CONTAINER_LOCK_PATH}")
    try:
        return CONTAINER_LOCK_PATH.read_text().strip()
    except OSError as error:
        raise DockerError(f"Failed to read {CONTAINER_LOCK_PATH}: {error}")


def remove_container_lockfile() -> str | None:
    """Delete the container lockfile, do not error if it doesn't exist."""

    print(f"Deleting {CONTAINER_LOCK_PATH}")
    try:
        return CONTAINER_LOCK_PATH.unlink(missing_ok=True)
    except OSError as error:
        raise DockerError(f"Failed to remove {CONTAINER_LOCK_PATH}: {error}")


def build() -> int:
    print("Warning: this will create an image at least the size of a CS2 client installation!")
    check_docker_available()
    return build_docker_image("cs2s")


def start() -> int:
    check_docker_available()
    container_id = start_docker_container("cs2s")
    write_container_lockfile(container_id)
    return 0


def shell() -> int:
    check_docker_available()
    if not CONTAINER_LOCK_PATH.exists():
        start()
    container_id = read_container_lockfile()
    return open_docker_container_shell(container_id)


def stop(force: bool = False) -> int:
    check_docker_available()
    container_id = read_container_lockfile()
    try:
        stop_docker_container(container_id)
    finally:
        if force:
            remove_container_lockfile()
    return 0


def main() -> int:
    """Called on program start."""

    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command")
    subparsers.add_parser("build")
    subparsers.add_parser("start")
    stop_parser = subparsers.add_parser("stop")
    stop_parser.add_argument("-f", "--force", help="Always delete the lockfile")
    subparsers.add_parser("shell")
    args = parser.parse_args()

    if args.command == "build":
        return build()
    if args.command == "start":
        return start()
    elif args.command == "shell":
        return shell()
    elif args.command == "stop":
        return stop(force=args.force)


if __name__ == "__main__":
    import sys

    try:
        main()
    except DockerError as error:
        print(error, file=sys.stderr)
