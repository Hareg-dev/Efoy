# 🚀 Quick Start - Run Efoy App

## ✅ FIXED: CardTheme Issue Resolved

The compilation error has been fixed. App should now run successfully!

---

## 🌐 Run on Chrome (RECOMMENDED)

```bash
cd C:\Users\DABC\Desktop\Dev\Efoy
flutter run -d chrome
```

**Expected output:**
```
Launching lib\main.dart on Chrome...
Building application for the web...
Chrome will open automatically...
Flutter app running!
```

⏱️ **First build:** ~2-3 minutes
⏱️ **Subsequent builds:** ~30 seconds

---

## 🔧 If Build Fails

### Fix 1: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Fix 2: Check Chrome is Available
```bash
flutter devices
# Should see: Chrome (web) • chrome • web-javascript
```

### Fix 3: Try Edge Instead
```bash
flutter run -d edge
```

---

## 📱 Run on Android

### Check Connected Devices
```bash
flutter devices
```

### Run on Specific Device
```bash
flutter run -d <device-id>
# Example: flutter run -d emulator-5554
```

### Run on Any Available Device
```bash
flutter run
```

---

## 🖥️ Run on Windows Desktop

### Check Windows Support
```bash
flutter doctor
```

### If Windows Toolchain Complete:
```bash
flutter run -d windows
```

### If Toolchain Incomplete:
Use Chrome instead (recommended)

---

## 🎯 Once App is Running

### Hot Reload (Recommended)
```
r = Hot reload (instant, preserves state)
R = Hot restart (full restart)
```

### Debug Tools
```
v = Open Flutter DevTools
d = Detach (app keeps running)
q = Quit app
```

### Chrome DevTools
```
F12 = Open Chrome DevTools
```

---

## ✅ What You'll See

### 1. Splash Screen (3 seconds)
- Dark navy gradient
- Efoy logo (white card)
- Amharic text: እፎይ
- Loading dots

### 2. Auth Screen
- Two tabs: Login | Activate License
- Device ID displayed
- **Yellow button: "Generate Test Key (30 Days)"**
- Click it → Key auto-fills → Click "Activate License"

### 3. Home Dashboard
- Green Net Profit card
- Quick metrics
- Alerts
- Bottom navigation

---

## 🧪 Quick Test Flow (2 Minutes)

1. **Launch:** `flutter run -d chrome`
2. **Wait:** Splash screen auto-navigates
3. **Activate:** 
   - Click "Activate License" tab
   - Click "Generate Test Key" button
   - Click "Activate License" button
4. **Explore:**
   - See Home dashboard
   - Click bottom nav tabs
   - Try settings icon (top-right)

---

## 🐛 Common Issues

### Issue: "Chrome not found"
```bash
flutter config --enable-web
flutter devices
```

### Issue: "Build failed"
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Issue: "Card type error"
✅ **FIXED** - Already resolved in latest code

### Issue: "Stuck at 'Building application'"
**Wait 2-3 minutes** for first build

### Issue: "License activation fails"
**Use the yellow "Generate Test Key" button**

---

## 💡 Pro Tips

1. **First Build is Slow** (2-3 min) - Normal!
2. **Use Hot Reload** (`r`) to see changes instantly
3. **Press F12** in Chrome for debugging
4. **Check Console** for any errors
5. **Test Key Button** is fastest way to activate

---

## 📸 Screenshots to Take

Once running, capture:
1. Splash screen
2. License activation screen
3. Home dashboard
4. Each bottom nav tab

---

## 🎉 Success Indicators

App is working if:
- ✅ Chrome opens automatically
- ✅ Splash screen displays
- ✅ Amharic text renders
- ✅ License activation works
- ✅ Home screen loads
- ✅ Navigation works
- ✅ No red error screens

---

## 🔄 Restart App

### While Running
```
R = Full restart (capital R)
```

### Fresh Start
```
q = Quit
flutter run -d chrome
```

---

## 🆘 Need Help?

1. Check console output for errors
2. Run `flutter doctor`
3. Try `flutter clean`
4. Use Edge if Chrome fails
5. Check TESTING_GUIDE.md

---

## ✨ Current Status

**App is currently building...**

Wait for message:
```
✓ Built web\main.dart.js
Flutter run key commands.
r Hot reload. 🔥🔥🔥
```

Then Chrome will open automatically!

---

**Next:** Once app opens, follow the Quick Test Flow above!
