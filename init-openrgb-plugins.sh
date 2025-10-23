#!/bin/bash
set -u  # no -e or -o pipefail to allow graceful failure handling

PLUGIN_DEST="${PLUGIN_DEST:-/config/xdg/config/OpenRGB/plugins}"
DEFAULT_PLUGIN="https://codeberg.org/OpenRGB/OpenRGBEffectsPlugin/releases/download/release_0.9/OpenRGBEffectsPlugin_0.9_Bookworm_64_f1411e1.so"
PLUGIN_URLS="${PLUGIN_URLS:-$DEFAULT_PLUGIN}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [init-openrgb-plugins] $*" >&2
}

log "Starting plugin initialization..."
mkdir -p "$PLUGIN_DEST"

IFS='|' read -r -a urls <<< "$PLUGIN_URLS"
plugin_count="${#urls[@]}"
log "Detected ${plugin_count} plugin(s) to check."

installed=0
skipped=0
failed=0

for url in "${urls[@]}"; do
    url="$(echo "$url" | xargs)"   # trim whitespace
    [[ -z "$url" ]] && continue

    file="$(basename "$url")"
    dest="${PLUGIN_DEST}/${file}"

    if [[ ! -f "$dest" ]]; then
        log "Downloading: $url"
        if curl -fsSL -o "$dest" "$url"; then
            chmod 0644 "$dest"
            log "✅ Installed plugin: $file"
            ((installed++))
        else
            log "❌ Failed to download: $url"
            ((failed++))
        fi
    else
        log "⏩ Skipped (already present): $file"
        ((skipped++))
    fi
done

log "All plugin checks complete."
log "Summary: ${installed} installed, ${skipped} skipped, ${failed} failed."
log "✅ Plugin initialization complete."