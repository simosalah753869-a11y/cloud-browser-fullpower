#!/usr/bin/env bash
set -e

PROFILE_DIR="$HOME/cloud_browser_profile"
mkdir -p "$PROFILE_DIR"

echo "=========================================================="
echo "🚀 جاري تشغيل متصفح الكلاود بأقصى قوة (Full-Power 60FPS + Audio + Arabic)..."
echo "=========================================================="

docker rm -f cloud_chrome >/dev/null 2>&1 || true

docker run -d \
  --name=cloud_chrome \
  --security-opt seccomp=unconfined \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Riyadh \
  -e SUBFOLDER=/ \
  -e TITLE="Cloud Browser 60FPS" \
  -e CHROME_CLI="https://www.youtube.com https://www.facebook.com" \
  -e DOCKER_MODS="linuxserver/mods:universal-package-install" \
  -e INSTALL_PACKAGES="fonts-noto-core|fonts-noto-color-emoji|fonts-hosny-amiri" \
  -p 3000:3000 \
  -p 3001:3001 \
  -v "$PROFILE_DIR:/config" \
  --shm-size="4gb" \
  --restart unless-stopped \
  lscr.io/linuxserver/chromium:latest

if ! command -v cloudflared >/dev/null 2>&1; then
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
  chmod +x /tmp/cloudflared
else
  cp "$(command -v cloudflared)" /tmp/cloudflared
fi

pkill -f "cloudflared tunnel" >/dev/null 2>&1 || true
nohup /tmp/cloudflared tunnel --no-autoupdate --url http://localhost:3000 > /tmp/cf_tunnel.log 2>&1 &

echo "⏳ جاري استخراج الرابط السحابي المباشر..."
for i in {1..20}; do
  URL=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" /tmp/cf_tunnel.log | head -n 1 || true)
  if [ -n "$URL" ]; then
    echo ""
    echo "=========================================================="
    echo "✅ متصفح الكلاود جاهز وشغال بأقصى قوة (4 Cores / 16GB RAM / 60FPS)!"
    echo "🔗 اضغط على هذا الرابط لفتح المتصفح فوراً:"
    echo "   $URL"
    echo "🔊 لتشغيل صوت يوتيوب: اضغط على السهم الصغير في يسار الشاشة ثم فعل أيقونة السماعة (Audio)."
    echo "=========================================================="
    break
  fi
  sleep 1
done
