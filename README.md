# OpenRGB Docker Images

Dockerfiles for building docker images to run OpenRGB on a TrueNAS SCALE Server.

**Yes, I know it's ridiculous to have RGB on a NAS, but why not?  Life should be fun!  And it's a learning experience.**

Images are published to DockerHub and versioned to match OpenRGB releases: https://hub.docker.com/r/swensorm/openrgb but, as always, are encouraged to build your own after inspecing the Dockerfiles since they are not offical.

## Images

| Dockerfile        | Description |
| Dockerfile.server | Based on Debian bookworm, only includes running a headless OpenRGB server.  Must forward port 6742 and be connected to from a separate GUI running on another machine. |
| Dockerfile.gui    | Based on jlesage/baseimage-gui includes the GUI version of OpenRGB and the server.  Supports forwarding port 5800 to access the OpenRGB GUI directly.  Can also still forward 6742 and access the server with a remote GUI.  Must also set the USER_ID and GROUP_ID values to a user/group that has access to the RGB devices you want to control (base image defaults to 1000), or 0 if you want to be a cowboy 🤠 |

Both images require being run in Privileged Mode or pass through specific devices if you know them.  Also requires the OpenRGB udev rules to be loaded on TrueNAS and `modprobe i2c-dev && modprobe i2c-i801`  run during system init.

## Building

Images only require a single build argument for the OpenRGB version to checkout and build.  The staged build will checkout directly from OpenRGB GitLabs repo, build from source, and create a new runtime image with the created binaries.

Examples:
```sh
docker build -t openrgb:release_0.9 --build-arg="OPENRGB_VERSION=release_0.9" -f Dockerfile.server .
```
```sh
docker build -t openrgb:release_0.9-gui --build-arg="OPENRGB_VERSION=release_0.9" -f Dockerfile.gui .
```
