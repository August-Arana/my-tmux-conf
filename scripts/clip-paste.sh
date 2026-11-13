#!/bin/sh
# Imprime el contenido de una selección del sistema: "clipboard" (default) o "primary".
sel=${1:-clipboard}
if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-paste >/dev/null 2>&1; then
    if [ "$sel" = primary ]; then wl-paste --primary --no-newline; else wl-paste --no-newline; fi
else
    xclip -out -selection "$sel"
fi 2>/dev/null
