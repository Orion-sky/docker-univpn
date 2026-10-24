#!/bin/bash
set -e

# --- Derive display/port details ---
DISPLAY_NUM=${DISPLAY#:} # Removes the leading ':'
LOCK_FILE="/tmp/.X${DISPLAY_NUM}-lock"
SOCKET_FILE="/tmp/.X11-unix/X${DISPLAY_NUM}"
RFB_PORT=$((5900 + DISPLAY_NUM))

# --- Full teardown of any previous Xvfb/x11vnc instance before a fresh start ---
echo "[vnc_startup] Cleaning up any previous Xvfb/x11vnc processes and stale files..."
pkill -9 -f "^Xvfb ${DISPLAY} " 2>/dev/null || true
pkill -9 -f "x11vnc .*-rfbport ${RFB_PORT}\\b" 2>/dev/null || true
rm -f "${LOCK_FILE}" "${SOCKET_FILE}"
echo "[vnc_startup] Cleanup finished."

mkdir -p "$HOME/.vnc"

# --- Start Xvfb ---
echo "[vnc_startup] Starting Xvfb on display ${DISPLAY} (${VNC_RESOLUTION}x${VNC_DEPTH})..."
Xvfb "${DISPLAY}" -screen 0 "${VNC_RESOLUTION}x${VNC_DEPTH}" -ac -nolisten tcp &

echo "[vnc_startup] Waiting for X socket ${SOCKET_FILE}..."
COUNT=0
until [ -S "${SOCKET_FILE}" ]; do
  sleep 1
  COUNT=$((COUNT + 1))
  if [ ${COUNT} -gt 20 ]; then
    echo "[vnc_startup] ERROR: Xvfb socket did not appear after 20 seconds"
    exit 1
  fi
done
echo "[vnc_startup] Xvfb is up."

# --- Configure keyboard layout now that the X server is up ---
# Must happen before any client (UniVPN) connects and builds its XKB keymap -
# Xvfb uses a complete Xorg-derived XKB implementation, unlike TigerVNC's Xvnc,
# which crashes Qt5's XKB handling the moment a dialog/window grabs keyboard focus.
if test -r /etc/default/keyboard && test -x /usr/bin/setxkbmap; then
  . /etc/default/keyboard
  setxkbmap -model "${XKBMODEL}" -layout "${XKBLAYOUT}" -variant "${XKBVARIANT}" "${XKBOPTIONS}"
  echo "[vnc_startup] Keyboard layout configured."
fi

# --- Set VNC password (x11vnc's own password-file format) ---
echo "[vnc_startup] Setting VNC password..."
x11vnc -storepasswd "$VNC_PW" "$HOME/.vnc/passwd" >/dev/null
chmod 600 "$HOME/.vnc/passwd"
echo "[vnc_startup] VNC password set."

# --- Start x11vnc in the foreground; supervisor tracks this process directly ---
echo "[vnc_startup] Starting x11vnc on RFB port ${RFB_PORT}..."
exec x11vnc -display "${DISPLAY}" -rfbport "${RFB_PORT}" -rfbauth "$HOME/.vnc/passwd" \
  -forever -shared -noxdamage -o "$HOME/.vnc/x11vnc.log"
