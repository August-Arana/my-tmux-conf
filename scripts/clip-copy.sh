#!/bin/sh
# Copia stdin al CLIPBOARD (Ctrl+V) y al PRIMARY (click medio) del sistema.
# Usa wl-clipboard si existe (Wayland nativo); si no, xclip vía XWayland.
tmp=$(mktemp) || exit 1
cat > "$tmp"
if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$tmp"
    wl-copy --primary < "$tmp"
else
    xclip -in -selection clipboard < "$tmp" >/dev/null 2>&1
    xclip -in -selection primary   < "$tmp" >/dev/null 2>&1
fi
rm -f "$tmp"
