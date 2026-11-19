#!/system/bin/sh
#
# Yumi module startup script (service.sh)
#

# 1. Wait for Android to finish booting
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 1
done

# 2. Define paths
[ -z "$MODDIR" ] && MODDIR=${0%/*}

DAEMON_PATH="$MODDIR/core/bin/yumi"
SCRIPTS_DIR="$MODDIR/scripts"
LOG_DIR="$MODDIR/logs"
LOG_FILE="$LOG_DIR/service.log"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

# Disable Oiface on OPPO, OnePlus, and Realme devices (commented out)
# if [ "$(getprop persist.sys.oiface.enable)" = "1" ]; then
#   setprop persist.sys.oiface.enable 0
#   echo "$(date): Oiface disabled." >> "$LOG_FILE"
# fi

# Disable the Xiaomi Joyose service (commented out)
# PACKAGE_NAME="com.xiaomi.joyose"
# if pm list packages -e | grep -q "$PACKAGE_NAME"; then
#   pm disable-user "$PACKAGE_NAME" >/dev/null 2>&1
#   pm clear "$PACKAGE_NAME" >/dev/null 2>&1
#   echo "$(date): Joyose service disabled and data cleared." >> "$LOG_FILE"
# fi

# 3. Stop the old daemon
killall -9 yumi > /dev/null 2>&1

# 4. Set permissions
chmod 755 "$DAEMON_PATH"
if [ -d "$SCRIPTS_DIR" ]; then
  chmod -R 755 "$SCRIPTS_DIR"
fi

# 5. Run the boost disabling script
# if [ -f "$SCRIPTS_DIR/disable_boost.sh" ]; then
#   echo "$(date): Executing disable_boost.sh" >> "$LOG_FILE"
#   "$SCRIPTS_DIR/disable_boost.sh"
# else
#   echo "$(date): disable_boost.sh not found" >> "$LOG_FILE"
# fi

# 6. Start the Yumi daemon
# Option A: Production mode (skip boot logging to reduce I/O)
nohup "$DAEMON_PATH" > /dev/null 2>&1 &

# Option B: Debug mode (log startup errors to logs/boot_error.log)
# nohup "$DAEMON_PATH" > "$LOG_DIR/boot_error.log" 2>&1 &