#!/bin/bash
# Remove -e to prevent command failures from aborting the script with an error code
set -u

PLUGIN_DEST="${PLUGIN_DEST:-${XDG_CONFIG_HOME:-/config/.config}/OpenRGB/plugins}"
# Point default plugin URL to the Bookworm .deb release package for Debian 12 / Qt 6.4.2 ABI compatibility
DEFAULT_PLUGIN="https://codeberg.org/OpenRGB/OpenRGBEffectsPlugin/releases/download/release_1.0/OpenRGBEffectsPlugin_1.0_Bookworm_amd64_0e0f1b4.deb"
PLUGIN_URLS="${PLUGIN_URLS:-$DEFAULT_PLUGIN}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [init-openrgb-plugins] $*" >&2
}

log "Starting plugin initialization..."
mkdir -p "$PLUGIN_DEST" || true

IFS='|' read -r -a urls <<< "$PLUGIN_URLS"
plugin_count="${#urls[@]}"
log "Detected ${plugin_count} plugin(s) to check."

installed=0
skipped=0
failed=0

for url in "${urls[@]}"; do
    url="$(echo "$url" | xargs)"
    [[ -z "$url" ]] && continue

    file="$(basename "$url")"
    
    # Handle .deb packages by extracting the embedded .so for native Debian 12 ABI alignment
    if [[ "$file" == *.deb ]]; then
        target_so="${file%.deb}.so"
        dest="${PLUGIN_DEST}/${target_so}"
        
        if [[ ! -f "$dest" ]]; then
            log "Downloading package: $url"
            tmp_deb="/tmp/${file}"
            tmp_extract="/tmp/extract_${file}"
            
            if curl -L --connect-timeout 10 --retry 3 --retry-delay 2 --retry-connrefused -fsSL -o "$tmp_deb" "$url"; then
                mkdir -p "$tmp_extract"
                dpkg-deb -x "$tmp_deb" "$tmp_extract"
                
                # Find extracted .so binary and place into destination
                extracted_so=$(find "$tmp_extract" -type f -name "*.so" | head -n 1)
                if [[ -n "$extracted_so" ]]; then
                    mv "$extracted_so" "$dest"
                    chmod 0644 "$dest" 2>/dev/null || true
                    log "✅ Extracted and installed plugin: ${target_so}"
                    ((installed++)) || true
                else
                    log "⚠️ No .so binary found inside package $file"
                    ((failed++)) || true
                fi
                
                rm -rf "$tmp_deb" "$tmp_extract" 2>/dev/null || true
            else
                log "⚠️ Failed to download $url (continuing startup without plugin)"
                rm -f "$tmp_deb" 2>/dev/null || true
                ((failed++)) || true
            fi
        else
            log "⏩ Skipped (already present): ${target_so}"
            ((skipped++)) || true
        fi
    else
        dest="${PLUGIN_DEST}/${file}"

        if [[ ! -f "$dest" ]]; then
            log "Downloading: $url"
            # Force curl check without failing script execution state
            if curl -L --connect-timeout 10 --retry 3 --retry-delay 2 --retry-connrefused -fsSL -o "$dest" "$url"; then
                chmod 0644 "$dest" 2>/dev/null || true
                log "✅ Installed plugin: $file"
                ((installed++)) || true
            else
                log "⚠️ Failed to download $url (continuing startup without plugin)"
                # Clean up partial downloads so future boots can try cleanly
                rm -f "$dest" 2>/dev/null || true
                ((failed++)) || true
            fi
        else
            log "⏩ Skipped (already present): $file"
            ((skipped++)) || true
        fi
    fi
done

log "All plugin checks complete."
log "Summary: ${installed} installed, ${skipped} skipped, ${failed} failed."
log "✅ Plugin initialization finished. Handing over to OpenRGB."

# Guarantee a clean 0 exit code so supervisor proceeds to launch the GUI app
exit 0