#!/system/bin/sh

# Restore Oiface on OPPO, OnePlus, and Realme devices
if [ -n "$(getprop persist.sys.oiface.enable)" ]; then
  setprop persist.sys.oiface.enable 1
fi

# Restore the Xiaomi Joyose service
PACKAGE_NAME="com.xiaomi.joyose"
if pm list packages | grep -q "$PACKAGE_NAME"; then
  pm enable "$PACKAGE_NAME" >/dev/null 2>&1
fi


echo "Yumi Scheduler was uninstalled. Please reboot your device."
