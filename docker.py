from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

REPOSITORY_PATH = Path(__file__).absolute().parent
CONTAINER_LOCK_PATH = REPOSITORY_PATH / ".docker"
IMAGE_ID_PATTERN = "writing image sha256:([abcdefABCDEF\\d]+)"


class DockerError(Exception):
    """For emitting errors on the CLI."""


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


def build_docker_image(name: str | None = None) -> str:
    """Build the adjacent Dockerfile."""

    print("Building the Docker image")
    extra_args = ("-t", name) if name is not None else ()
    process = subprocess.run(
        ("docker", "build", REPOSITORY_PATH, *extra_args),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
    )

    if process.returncode != 0:
        raise DockerError(f"Failed to build the Docker image: {process.stderr}")

    image_id_match = re.search(IMAGE_ID_PATTERN, process.stderr)
    if image_id_match is None:
        raise DockerError(f"Failed to determine the image ID: {process.stderr}")
    image_id = image_id_match.group(1)

    return image_id


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


def main() -> int:
    """Called on program start."""

    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command")
    subparsers.add_parser("start")
    subparsers.add_parser("stop")
    subparsers.add_parser("shell")
    args = parser.parse_args()

    if args.command == "start":
        check_docker_available()
        image_id = build_docker_image("cs2s")
        container_id = start_docker_container(image_id)
        write_container_lockfile(container_id)
        return 0

    elif args.command == "shell":
        check_docker_available()
        container_id = read_container_lockfile()
        return open_docker_container_shell(container_id)

    elif args.command == "stop":
        check_docker_available()
        container_id = read_container_lockfile()
        stop_docker_container(container_id)
        remove_container_lockfile()
        return 0


if __name__ == "__main__":
    import sys

    try:
        main()
    except DockerError as error:
        print(error, file=sys.stderr)
