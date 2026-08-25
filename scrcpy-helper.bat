@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title scrcpy-helper-ar v2

echo.
echo ===============================================
echo       scrcpy-helper-ar v2 - مساعد إدراك
echo ===============================================
echo.

where adb >nul 2>&1
if errorlevel 1 (
  echo [خطأ] لم يتم العثور على ADB.
  echo ضع هذا الملف داخل مجلد scrcpy الرسمي أو أضف ADB إلى PATH.
  goto :end_error
)

where scrcpy >nul 2>&1
if errorlevel 1 (
  echo [خطأ] لم يتم العثور على scrcpy.
  echo ضع هذا الملف داخل مجلد scrcpy الرسمي أو أضف scrcpy إلى PATH.
  goto :end_error
)

set "DEVICE_SERIAL="
set "DEVICE_STATE="
set /a DEVICE_COUNT=0

for /f "skip=1 tokens=1,2" %%A in ('adb devices 2^>nul') do (
  if not "%%A"=="" (
    if "%%B"=="device" (
      set /a DEVICE_COUNT+=1
      if not defined DEVICE_SERIAL set "DEVICE_SERIAL=%%A"
    )
    if "%%B"=="unauthorized" set "DEVICE_STATE=unauthorized"
    if "%%B"=="offline" set "DEVICE_STATE=offline"
  )
)

if not defined DEVICE_SERIAL (
  if "!DEVICE_STATE!"=="unauthorized" (
    echo [غير مصرح] افتح الهاتف ووافق على رسالة السماح بتصحيح USB.
    goto :end_error
  )
  if "!DEVICE_STATE!"=="offline" (
    echo [غير متصل] افصل الكابل وأعد تشغيل تصحيح USB ثم حاول مجددًا.
    goto :end_error
  )
  echo [لا يوجد جهاز] لم يعثر ADB على هاتف متصل.
  echo جرّب كابل بيانات ومنفذ USB آخر، وافتح قفل الهاتف.
  goto :end_error
)

if !DEVICE_COUNT! GTR 1 (
  echo [تنبيه] يوجد أكثر من جهاز. سيُستخدم الجهاز الأول: !DEVICE_SERIAL!
)

set "MODEL=غير معروف"
set "ANDROID_VERSION=غير معروف"
set "SDK=0"

for /f "usebackq delims=" %%M in (`adb -s "!DEVICE_SERIAL!" shell getprop ro.product.model 2^>nul`) do set "MODEL=%%M"
for /f "usebackq delims=" %%V in (`adb -s "!DEVICE_SERIAL!" shell getprop ro.build.version.release 2^>nul`) do set "ANDROID_VERSION=%%V"
for /f "usebackq delims=" %%S in (`adb -s "!DEVICE_SERIAL!" shell getprop ro.build.version.sdk 2^>nul`) do set "SDK=%%S"

echo [متصل] !MODEL! - Android !ANDROID_VERSION!
if !SDK! GEQ 30 (
  echo [الصوت] مدعوم في scrcpy على هذا الإصدار من أندرويد.
) else (
  echo [الصوت] غير مدعوم عبر scrcpy في Android 10 وما قبله.
)

:menu
echo.
echo اختر وضع التشغيل:
echo   1^) متوازن - 1080 / 30FPS
echo   2^) أسرع أداء - 720 / 30FPS / من دون صوت
echo   3^) جودة عالية - 1920 / 60FPS / 16Mbps
echo   4^) عرض تقديمي - ملء الشاشة وإبقاء الهاتف نشطًا
echo   5^) تسجيل الشاشة - ملف MKV
echo   6^) إعدادات scrcpy الافتراضية
echo   7^) إنشاء تقرير تشخيصي
echo   8^) خروج
echo.
choice /c 12345678 /n /m "اكتب رقم الخيار: "

if errorlevel 8 goto :end_ok
if errorlevel 7 goto :diagnostic
if errorlevel 6 set "SCRCPY_ARGS=" & goto :run
if errorlevel 5 set "SCRCPY_ARGS=--record=scrcpy-recording-!RANDOM!.mkv" & goto :run
if errorlevel 4 set "SCRCPY_ARGS=--max-size=1080 --max-fps=30 --fullscreen --stay-awake --turn-screen-off" & goto :run
if errorlevel 3 set "SCRCPY_ARGS=--max-size=1920 --max-fps=60 --video-bit-rate=16M" & goto :run
if errorlevel 2 set "SCRCPY_ARGS=--max-size=720 --max-fps=30 --video-bit-rate=4M --no-audio --turn-screen-off" & goto :run
if errorlevel 1 set "SCRCPY_ARGS=--max-size=1080 --max-fps=30 --turn-screen-off" & goto :run

:run
echo.
echo سيتم تنفيذ:
echo scrcpy --serial "!DEVICE_SERIAL!" !SCRCPY_ARGS!
echo.
scrcpy --serial "!DEVICE_SERIAL!" !SCRCPY_ARGS!
if errorlevel 1 (
  echo.
  echo [فشل التشغيل] راجع رسالة الخطأ الظاهرة أعلاه.
  goto :end_error
)
goto :end_ok

:diagnostic
set "REPORT=scrcpy-diagnostic.txt"
(
  echo scrcpy-helper-ar diagnostic report
  echo =================================
  echo Device model: !MODEL!
  echo Android version: !ANDROID_VERSION!
  echo Android SDK: !SDK!
  echo ADB state: device
  echo.
  echo ADB version:
  adb --version 2^>nul
  echo.
  echo scrcpy version:
  scrcpy --version 2^>nul
) > "!REPORT!"
echo.
echo تم إنشاء !REPORT! من دون تضمين الرقم التسلسلي للهاتف.
goto :menu

:end_error
echo.
pause
exit /b 1

:end_ok
echo.
pause
exit /b 0
