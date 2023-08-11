#!/bin/sh

if [ -z ${VNCPASSWD} ]; then
    echo "Please set $$VNCPASSWD"
    exit 1
fi

export TMP_HOME=/tmp/user
mkdir -p ${TMP_HOME}
ln -s /home/user/.pki ${TMP_HOME}/.pki
export HOME=${TMP_HOME}
export XDG_CACHE_HOME=${HOME}/.cache

export VNC_PASSWD=${HOME}/.vncpasswd
touch ${VNC_PASSWD}
chmod 600 ${VNC_PASSWD}
echo ${VNCPASSWD} | vncpasswd -f > ${VNC_PASSWD}

export DISCONNECT_DELAY=${DISCONNECT_DELAY:-120}
export IDLE_TIMEOUT=${IDLE_TIMEOUT:-900}
export FRAME_RATE=${FRAME_RATE:-30}

export DISPLAY=:20
Xtigervnc :20 -PasswordFile ${VNC_PASSWD} -geometry ${VIEWPORT_WIDTH}x${VIEWPORT_HEIGHT} -NeverShared \
    -MaxDisconnectionTime ${DISCONNECT_DELAY} -IdleTimeout ${IDLE_TIMEOUT} \
    -AcceptCutText=0 \
    -FrameRate ${FRAME_RATE} -CompareFB 1 &

export GOOGLE_API_KEY="no"
export GOOGLE_DEFAULT_CLIENT_ID="no"
export GOOGLE_DEFAULT_CLIENT_SECRET="no"
export CHROME_HEADLESS=1

chromium \
    --disable-dev-shm-usage \
    --disable-features=ChromeWhatsNewUI \
    --disable-threaded-scrolling \
    --disable-threaded-animation \
    --disable-login-animations \
    --disable-modal-animations \
    --disable-notifications \
    --disable-file-system \
    --disable-extensions \
    --disable-smooth-scrolling \
    --animation-duration-scale=0 \
    --wm-window-animations-disabled \
    --enable-low-end-device-mode \
    --window-position=0,0 \
    --window-size=${VIEWPORT_WIDTH},${VIEWPORT_HEIGHT} \
    --proxy-server="proxy0-418f1090cac5bb897d919b628e87950c.menlosecurity.com:3129"
