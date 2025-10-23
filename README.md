# 📦 CajunCoding/OpenRGB-GUI-Unraid

A containerized build of OpenRGB with GUI and server mode support, optimized for Unraid. Includes automatic plugin initialization and support for AMD/Intel RGB devices via kernel modules.

🍴 Forked from the great starting point and tailored for Unraid!

### ⛔ WARNINGS

Please see the [Warnings](https://gitlab.com/CalcProgrammer1/OpenRGB#warning), [Supported Devices](https://openrgb.org/devices.html), [SMBus Access](https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/SMBusAccess.md), and other troubleshooting help on the offical OpenRGB project [website](https://openrgb.org/) and [GitLab](https://gitlab.com/CalcProgrammer1/OpenRGB) page.

Running any container with Privleged Mode On AND User/Group set to root (0) is the same as running the container bare metal on the host and gives it full access to your system. Take note and act accordingly!

## 🚀 Features
- Includes Web VNC GUI
- OpenRGB Plugins bootstrap (via `init-openrgb-plugins.sh`) with logging
- Tailored for Unraid
- Running the updated OpenRGB release 0.9 and associated plugin module

## 🔌 Plugin Initialization
On container startup, the script `/init-openrgb-plugins.sh` runs automatically to ensure plugins are present. It supports multiple plugin URLs via a pipe-delimited environment variable that can be specified int he Unraid template; defaulting to the current *OpenRGB Effects plugin* module for this release: https://openrgb.org/plugin_effects.html

#### Template Variable:

`PLUGIN_URLS`="https://codeberg.org/OpenRGB/OpenRGBEffectsPlugin/releases/download/release_0.9/OpenRGBEffectsPlugin_0.9_Bookworm_64_f1411e1.so"

If omitted, it defaults to the *OpenRGB Effects Plugin*. For multiple other custom plugins you may use a pipe delimited list of urls.

#### 🪵Log Output Example:

2025-10-23 00:52:01 [init-openrgb-plugins] ✅ Installed plugin: OpenRGBEffectsPlugin_0.9_Bookworm_64_f1411e1.so
2025-10-23 00:52:02 [init-openrgb-plugins] ⏩ Skipped (already present): MyOtherPlugin.so
2025-10-23 00:52:02 [init-openrgb-plugins] Summary: 1 installed, 1 skipped, 0 failed.

## 🛠 Unraid Setup for RGB Device Access
To enable RGB control for AMD and Intel motherboards, you may need to load kernel modules manually.

Add these to `/boot/config/go`:

###### ✅ AMD (e.g. ASUS, MSI boards)
```
modprobe i2c-dev
modprobe i2c-piix4
```

###### ✅ Intel (e.g. ASUS Z-series boards)
```
modprobe i2c-dev
modprobe i2c-i801
```

Example of final `/boot/confic/go` file:
```
#!/bin/bash
# Start the Management Utility
/usr/local/sbin/emhttp 

#CajunCoding - 10/23/2025
# Added to enable OpenRGB on the MSI B450 Mortar Titanium Motherboard as outlined in the Github Readme:
# https://github.com/cajuncoding/OpenRGB-GUI-Unraid
modprobe i2c-dev
modprobe i2c-piix4
```

These modules expose the SMBus interface required by OpenRGB. You can verify device presence with:
```
ls /dev/i2c-*
```

If no devices appear, check your BIOS settings for SMBus or RGB control options.

## 📦 Unraid Template Setup

In your Unraid Docker template:

- **Repository:** `cajuncoding/openrgb-gui-unraid:latest`
- **Environment Variables:**
  - `PLUGIN_URLS` → pipe-delimited list of plugin URLs
- **Volume Mappings:**
  - `/config` → persistent storage for OpenRGB settings and plugins

## 🎨 Loading RGB Profiles via Command Line

After configuring OpenRGB profiles through the GUI the files are saved as `.orp` into the AppData folder for Unraid.

The profiles can then be loaded running docker exec commands.  This allows you to dynamically change the RGB based on various events, integrations, etc. from console scripts.

The name of the container is required; you can run `docker ps` on the host to find all running container names but it will generally match or be accessible from the Unraid Docker template.

To run a profile named `Off.orp` in a Docker Image named `openrgb-gui-unraid`:
```
docker exec openrgb-gui-unraid /usr/app/openrgb --profile /config/xdg/config/OpenRGB/Off.orp
```
