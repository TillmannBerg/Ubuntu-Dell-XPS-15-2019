#!/bin/bash
DISPLAYNAME=$(xrandr --listmonitors | awk '$1 == "0:" {print $4}')

OLED_BR=`xrandr --verbose | grep -i brightness | cut -f2 -d ' '`
CURR=`LC_ALL=C /usr/bin/printf "%.*f" 1 $OLED_BR`

MIN=0
MAX=1.2

if [ "$1" == "up" ]; then
    VAL=`echo "scale=1; $CURR+0.1" | bc`
else
    VAL=`echo "scale=1; $CURR-0.1" | bc`
fi

if (( `echo "$VAL < $MIN" | bc -l` )); then
    VAL=$MIN
elif (( `echo "$VAL > $MAX" | bc -l` )); then
    VAL=$MAX
else
    `xrandr --output $DISPLAYNAME --brightness $VAL` 2>&1 >/dev/null | logger -t oled-brightness
fi

# Set Intel backlight to fake value
# to sync OSD brightness indicator to actual brightness
INTEL_PANEL="/sys/devices/pci0000:00/0000:00:02.0/drm/card0/card0-eDP-1/intel_backlight/"
if [ -d "$INTEL_PANEL" ]; then
    PERCENT=`echo "scale=4; $VAL/$MAX" | bc -l`
    INTEL_MAX=$(cat "$INTEL_PANEL/max_brightness")
    INTEL_BRIGHTNESS=`echo "scale=4; $PERCENT*$INTEL_MAX" | bc -l`
    INTEL_BRIGHTNESS=`LC_ALL=C /usr/bin/printf "%.*f" 0 $INTEL_BRIGHTNESS`
    echo $INTEL_BRIGHTNESS > "$INTEL_PANEL/brightness"
fi
