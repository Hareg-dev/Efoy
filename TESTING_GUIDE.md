# 🧪 Efoy Testing Guide - Quick Start

## 🚀 Launch Commands

### Chrome (Web) - **EASIEST FOR TESTING**
```bash
flutter run -d chrome
```
✅ **Best for:** Quick testing, UI review, debugging
✅ **No setup needed**
✅ **Hot reload works great**

### Edge (Web)
```bash
flutter run -d edge
```

### Android (if connected)
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just
flutter run
```

### Windows Desktop
```bash
flutter run -d windows
```
⚠️ **Note:** Requires Visual Studio C++ tools
💡 **Fix:** Run `flutter doctor` and follow instructions

---

## 🎯 Testing Flow (5 Minutes)

### Step 1: Launch App
```bash
flutter run -d chrome
```

### Step 2: Watch Splash Screen
- ✅ Logo displays
- ✅ Amharic text: እፎይ
- ✅ Tagline: በእፎይ እርፍ ይበሉ
- ✅ Auto-navigates after 3 seconds

### Step 3: Test License Activation

**On Auth Screen:**
1. Switch to **"Activate License"** tab
2. See your Device ID displayed
3. Click **"Generate Test Key (30 Days)"** button (debug mode only)
4. License key auto-fills
5. Click **"Activate License"**
6. ✅ Success message appears
7. ✅ Auto-navigates to Home

**Alternative (Manual):**
1. Copy the Device ID
2. Paste any valid license key
3. Or use console method (see below)

### Step 4: Explore Home Dashboard
- ✅ See Net Profit card (green gradient)
- ✅ See period filters (Today/Week/Month)
- ✅ See quick metrics (0 transactions)
- ✅ See alerts section

### Step 5: Test Navigation
Click bottom nav icons:
- 🏠 Home - Dashboard
- 💳 Sell - "Coming Soon"
- 📦 Inventory - "Coming Soon"
- 💰 Expenses - "Coming Soon"
- 👤 Profile - "Coming Soon"

✅ **Expected:** Smooth transitions, teal highlight on active

---

## 🔑 License Key Generation Methods

### Method 1: In-App Button (EASIEST) ⭐
1. Launch app in debug mode
2. Go to "Activate License" tab
3. Click **"Generate Test Key (30 Days)"**
4. Key auto-fills
5. Click Activate

### Method 2: Console Generator
```dart
// In lib/main.dart, uncomment these lines:
import 'core/utils/test_helpers.dart';

void main() async {
  // ...
  await TestHelpers.generateTestLicenses();
  // ...
}
```

Then run app. Console will print:
```
═══════════════════════════════════════════
🔑 EFOY TEST LICENSE GENERATOR
═══════════════════════════════════════════

📱 Device Information:
   Platform: Web
   Model: Chrome
   
📍 Device ID: A1B2-C3D4-E5F6-G7H8
═══════════════════════════════════════════

🎫 7-Day Trial License:
   eyJk... [long string]

📅 30-Day Monthly License:
   eyJk... [long string]

♾️  Lifetime License:
   eyJk... [long string]
```

Copy any key and paste in app.

---

## 🎨 Visual Testing Checklist

### Splash Screen
- [ ] Dark gradient background
- [ ] White rounded card with logo
- [ ] Amharic text centered
- [ ] Loading dots animate
- [ ] Auto-navigation works

### Auth Screen
- [ ] Two tabs visible
- [ ] Device info card shows
- [ ] Device ID copyable
- [ ] License input works
- [ ] Test key button shows (debug)
- [ ] Error messages appear (invalid key)
- [ ] Success message appears (valid key)
- [ ] Navigation works

### Home Screen
- [ ] Header displays correctly
- [ ] Net profit card has green gradient
- [ ] Period filters visible
- [ ] Metrics cards display
- [ ] Alerts section shows
- [ ] Empty state displays
- [ ] Bottom nav works

### Colors Match Brand
- [ ] Primary Teal: #007A60
- [ ] Success Green: #0EC254
- [ ] Navy gradient on splash
- [ ] White backgrounds on cards

---

## 🐛 Common Issues & Fixes

### Issue: "Visual Studio toolchain not found"
**Solution:** Use Chrome instead
```bash
flutter run -d chrome
```

### Issue: "Device ID shows 'Loading...'"
**Solution:** Wait a few seconds, it's async

### Issue: "License activation fails"
**Solutions:**
1. Use the "Generate Test Key" button
2. Check Device ID matches the key
3. Verify key is not expired
4. Try console method

### Issue: "Logo doesn't show"
**Solution:** Check `asset/efoy.jpg` exists
```bash
# Verify
ls asset/efoy.jpg
```

### Issue: "Hot reload not working"
**Solutions:**
1. Press `r` in terminal
2. Press `R` for full restart
3. Stop and rerun `flutter run`

### Issue: "Amharic text shows boxes"
**Solution:** Fonts loading, give it a moment

---

## 📱 Platform-Specific Testing

### Chrome (Web)
✅ **Pros:**
- Fastest testing
- Easy debugging (F12)
- Hot reload instant
- No setup needed

⚠️ **Limitations:**
- Camera/barcode won't work (future features)
- Some native features limited

### Android
✅ **Pros:**
- Real device experience
- All features work
- Production-like

⚠️ **Setup:**
```bash
# Enable USB debugging on device
# Connect device
flutter devices
flutter run
```

### Windows Desktop
✅ **Pros:**
- Native performance
- Large screen testing

⚠️ **Setup:** Requires Visual Studio C++ tools

---

## 🔍 Debug Tools

### Chrome DevTools
1. Press `F12` in Chrome
2. Check console for errors
3. Use network tab
4. Inspect elements

### Flutter DevTools
```bash
# While app is running, press 'v' in terminal
# Opens browser with Flutter DevTools
```

### Hot Reload
```bash
# In terminal while running:
r = hot reload
R = hot restart
d = detach (keep running)
q = quit
```

---

## ✅ Testing Checklist

### First Run Test
- [ ] App launches without errors
- [ ] Splash screen displays
- [ ] Navigation works
- [ ] License activation works
- [ ] Home screen displays
- [ ] Bottom nav works
- [ ] No console errors

### UI/UX Test
- [ ] Colors match brand
- [ ] Text readable
- [ ] Buttons clickable
- [ ] Animations smooth
- [ ] Responsive layout
- [ ] Amharic text renders

### Functionality Test
- [ ] Device ID generates
- [ ] Copy to clipboard works
- [ ] License validation works
- [ ] Invalid key shows error
- [ ] Valid key navigates
- [ ] Tab switching works
- [ ] Navigation persists

---

## 📊 Performance Check

### Load Time
- Splash → Auth: < 3 seconds ✅
- License activation: < 1 second ✅
- Navigation: Instant ✅

### Memory
- Check DevTools memory tab
- Should be < 100MB for web

### Console
- No errors expected
- Warnings okay for now

---

## 🎯 Ready for Next Phase?

Phase 1 complete when:
- [x] App runs on Chrome
- [x] Splash screen works
- [x] License activation works
- [x] Navigation works
- [x] Home screen displays
- [x] No critical bugs

**Status: Ready for Phase 2! 🚀**

---

## 💡 Quick Tips

1. **Use Chrome** for fastest testing
2. **Use Test Key Button** for instant activation
3. **Hot Reload** saves time (press `r`)
4. **F12** for debugging
5. **Check Console** for errors
6. **Screenshot Issues** to remember bugs

---

## 📞 Need Help?

1. Check console for errors
2. Run `flutter doctor`
3. Try `flutter clean` then `flutter pub get`
4. Restart app
5. Try different device (Chrome)

---

**Happy Testing! 🎉**
