#!/usr/bin/env bash
# -------- scrcpy-helper-ar ----------
echo "=== توصيل الجهاز... تأكد أن USB Debugging مفعَّل ==="
adb devices | grep -w "device" >/dev/null 2>&1 || {
  echo "لا يوجد جهاز متصل!"
  exit 1
}

# إعدادات مقترَحة: حجم 1080، 30FPS، إطفاء شاشة الهاتف
scrcpy --max-size 1080 --max-fps 30 --turn-screen-off
