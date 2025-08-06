@echo off
REM -------- scrcpy-helper-ar ---------
echo === توصيل الجهاز... تأكد أن USB Debugging مفعَّل ===
adb devices
if %ERRORLEVEL% neq 0 (
  echo لم يتم العثور على جهاز. تأكد من تفعيل USB Debugging.
  pause
  exit /b
)

REM إعدادات مقترَحة: حجم 1080، 30FPS، إطفاء شاشة الهاتف
scrcpy --max-size 1080 --max-fps 30 --turn-screen-off
pause
