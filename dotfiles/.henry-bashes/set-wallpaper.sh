#!/bin/bash

WALLPAPER="$HOME/Pictures/arch-linux-wallpaper.jpg"

if [ -f "$WALLPAPER" ]; then
    feh --bg-fill "$WALLPAPER"
fi
