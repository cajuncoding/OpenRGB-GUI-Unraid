# OpenRGB Docker Images

Dockerfiles for building docker images to run OpenRGB inside a container (such as on a NAS/TrueNAS SCALE Server, Unraid, etc.).

**Yes, I know it's ridiculous to have RGB on a NAS, but why not?  Life should be fun!  And it's a learning experience.**

## OpenRGB Project

Please see the [Warnings](https://gitlab.com/CalcProgrammer1/OpenRGB#warning), [Supported Devices](https://openrgb.org/devices.html), [SMBus Access](https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/SMBusAccess.md), and other troubleshooting help on the offical OpenRGB project [website](https://openrgb.org/) and [GitLab](https://gitlab.com/CalcProgrammer1/OpenRGB) page.

## Images

Images are published to DockerHub.  They are versioned to match OpenRGB releases: https://hub.docker.com/r/swensorm/openrgb but, as always, are encouraged to build your own after inspecing the Dockerfiles since they are not offical.

| Dockerfile        | Description |
| ----------------- | ----------- |
| Dockerfile.server | Based on Debian bookworm, only includes running a headless OpenRGB server.  Must forward port 6742 and be connected to from a separate GUI running on another machine. |
| Dockerfile.gui    | Based on jlesage/baseimage-gui includes the GUI version of OpenRGB and the server.  Supports forwarding port 5800 to access the OpenRGB GUI directly.  Can also still forward 6742 and access the server with a remote GUI.  Must also set the USER_ID and GROUP_ID values to a user/group that has access to the RGB devices you want to control (base image defaults to 1000) |

## Compose

Example Docker Compose

```
services:
  openrgb:
    image: swensorm/openrgb:release_0.9-gui
    restart: unless-stopped
    environment:
      - TZ=America/New_York
      # Choose User/Group that has access on the host to all devices needing control
      - USER_ID=568
      - GROUP_ID=568
      # GUI Image only, adds additional groups to control devices
      - SUB_GROUP_IDS=132
    ports:
      - 15800:5800
    devices:
      - /dev/i2c-0:/dev/i2c-0
      - /dev/hidraw0:/dev/hidraw0
    volumes:
      - /mnt/pool/openrgb:/config/xdg/config/OpenRGB
```

## Building

Images only require a single build argument for the OpenRGB version to checkout and build.  The staged build will checkout directly from OpenRGB GitLabs repo, build from source, and create a new runtime image with the created binaries.

Examples:
```sh
docker build -t openrgb:release_0.9 --build-arg="OPENRGB_VERSION=release_0.9" -f Dockerfile.server .
```
```sh
docker build -t openrgb:release_0.9-gui --build-arg="OPENRGB_VERSION=release_0.9" -f Dockerfile.gui .
```

## Devices

While I don't recommend running the container with "Privileged Mode" all the time, it can be VERY useful when starting out just to find what devices you need.

If you know your specific devices you want to control, they can be passed through individually to the container.  RGB RAM will usually be on the i2c bus with devices like `/dev/i2c-0`, `/dev/i2c-1`, etc.  USB Devices will be mounted on the hid bus and create a raw interface such as `/dev/hidraw0`.

On the host device `modprobe i2c-dev` will need to be run on system init along with the specific manufacturer driver.  See the OpenRGB [SMBus Access](https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/SMBusAccess.md#linux) docs for futher details.  TrueNAS has Init/Shutdown Scripts in the System->Advanced settings where they can be added as POSTINIT commands (e.g. `modprobe i2c-dev && modprobe i2c-i801`).
* Intel
  * `modprobe i2c-i801`
* AMD
  * `modprobe i2c-piix4`
* Nuvoton
  * `modprobe i2c-nct6793`

## Access

The user running inside the container is required to have access to the RGB devices you want to control.  ACLs do not pass through to containers so the owner or group rights will need to match both on the host machine and inside the container.  i2c devices, at least on TrueNAS, have a group of 132.  hidraw devices are owned by root unless you want to create udev rules through the TrueNAS CLI Sysctl tunables to change them on device load.

If you are unable to use a user that has access to all of the devices you want to control then the container will need to be run as root.

## ⛔ WARNING

Running any container with Privleged Mode On AND User/Group set to root (0) is the same as running the container bare metal on the host and gives it full access to your system.  I strongly suggest doing one or the other only, or neither if possible!

## RGB Profiles

After configuring OpenRGB profiles through the GUI the files can be saved as `.orp` and loaded on demand inside either container image (GUI or Server).  Map a volume from the host to the OpenRGB config folder so they are persisted across restarts and available to the container.

```
volumes:
  - /apps/openrgb:/config/xdg/config/OpenRGB
```

The profiles can then be loaded running docker exec commands.  The name of the container is required.  On a TrueNAS server running as a custom app named "openrgb", the container would be named `ix-openrgb-openrgb-1`.  Run `docker ps` on the host to find all running container names.

```
docker exec ix-openrgb-openrgb-1 /usr/app/openrgb --profile /config/xdg/config/OpenRGB/Off.orp
```
