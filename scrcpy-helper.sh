#!/usr/bin/env bash

set -u

printf '\n%s\n' '==============================================='
printf '%s\n' '      scrcpy-helper-ar v2 - مساعد إدراك'
printf '%s\n\n' '==============================================='

if ! command -v adb >/dev/null 2>&1; then
  printf '%s\n' '[خطأ] لم يتم العثور على ADB. ثبّته أو أضفه إلى PATH.' >&2
  exit 1
fi

if ! command -v scrcpy >/dev/null 2>&1; then
  printf '%s\n' '[خطأ] لم يتم العثور على scrcpy. ثبّته أو أضفه إلى PATH.' >&2
  exit 1
fi

adb_output="$(adb devices 2>/dev/null)"
device_list="$(printf '%s\n' "$adb_output" | awk 'NR > 1 && $2 == "device" {print $1}')"
device_count="$(printf '%s\n' "$device_list" | awk 'NF {count++} END {print count+0}')"
device="$(printf '%s\n' "$device_list" | awk 'NF {print; exit}')"

if [[ -z "$device" ]]; then
  if printf '%s\n' "$adb_output" | grep -q $'\tunauthorized$'; then
    printf '%s\n' '[غير مصرح] افتح الهاتف ووافق على رسالة السماح بتصحيح USB.' >&2
  elif printf '%s\n' "$adb_output" | grep -q $'\toffline$'; then
    printf '%s\n' '[غير متصل] افصل الكابل وأعد تشغيل تصحيح USB ثم حاول مجددًا.' >&2
  else
    printf '%s\n' '[لا يوجد جهاز] جرّب كابل بيانات ومنفذ USB آخر وافتح قفل الهاتف.' >&2
  fi
  exit 1
fi

if (( device_count > 1 )); then
  printf '[تنبيه] يوجد أكثر من جهاز. سيُستخدم الجهاز الأول: %s\n' "$device"
fi

model="$(adb -s "$device" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
android_version="$(adb -s "$device" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
sdk="$(adb -s "$device" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')"

model="${model:-غير معروف}"
android_version="${android_version:-غير معروف}"
sdk="${sdk:-0}"

printf '[متصل] %s - Android %s\n' "$model" "$android_version"
if [[ "$sdk" =~ ^[0-9]+$ ]] && (( sdk >= 30 )); then
  printf '%s\n' '[الصوت] مدعوم في scrcpy على هذا الإصدار من أندرويد.'
else
  printf '%s\n' '[الصوت] غير مدعوم عبر scrcpy في Android 10 وما قبله.'
fi

while true; do
  printf '\n%s\n' 'اختر وضع التشغيل:'
  printf '%s\n' '  1) متوازن - 1080 / 30FPS'
  printf '%s\n' '  2) أسرع أداء - 720 / 30FPS / من دون صوت'
  printf '%s\n' '  3) جودة عالية - 1920 / 60FPS / 16Mbps'
  printf '%s\n' '  4) عرض تقديمي - ملء الشاشة وإبقاء الهاتف نشطًا'
  printf '%s\n' '  5) تسجيل الشاشة - ملف MKV'
  printf '%s\n' '  6) إعدادات scrcpy الافتراضية'
  printf '%s\n' '  7) إنشاء تقرير تشخيصي'
  printf '%s\n' '  8) خروج'
  printf '%s' 'اكتب رقم الخيار: '
  IFS= read -r choice

  args=()
  case "$choice" in
    1) args=(--max-size=1080 --max-fps=30 --turn-screen-off) ;;
    2) args=(--max-size=720 --max-fps=30 --video-bit-rate=4M --no-audio --turn-screen-off) ;;
    3) args=(--max-size=1920 --max-fps=60 --video-bit-rate=16M) ;;
    4) args=(--max-size=1080 --max-fps=30 --fullscreen --stay-awake --turn-screen-off) ;;
    5) args=("--record=scrcpy-recording-$(date +%Y%m%d-%H%M%S).mkv") ;;
    6) args=() ;;
    7)
      report='scrcpy-diagnostic.txt'
      {
        printf '%s\n' 'scrcpy-helper-ar diagnostic report'
        printf '%s\n' '================================='
        printf 'Device model: %s\n' "$model"
        printf 'Android version: %s\n' "$android_version"
        printf 'Android SDK: %s\n' "$sdk"
        printf '%s\n\n' 'ADB state: device'
        printf '%s\n' 'ADB version:'
        adb --version 2>/dev/null
        printf '\n%s\n' 'scrcpy version:'
        scrcpy --version 2>/dev/null
      } > "$report"
      printf 'تم إنشاء %s من دون تضمين الرقم التسلسلي للهاتف.\n' "$report"
      continue
      ;;
    8) exit 0 ;;
    *) printf '%s\n' 'خيار غير صحيح.'; continue ;;
  esac

  printf '\n%s' 'سيتم تنفيذ: scrcpy'
  printf ' %q' --serial "$device" "${args[@]}"
  printf '\n\n'
  scrcpy --serial "$device" "${args[@]}"
  exit $?
done
