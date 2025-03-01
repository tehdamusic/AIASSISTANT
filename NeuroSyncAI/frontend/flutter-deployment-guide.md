# ADHD Assistant App: Deployment Guide

This guide will walk you through three deployment options for your ADHD Assistant app:
1. Running on an Android phone in debug mode
2. Using local emulators in Android Studio or VS Code
3. Building a production APK for sideloading

## Prerequisites

Before getting started, ensure you have:

- Flutter SDK installed and updated (`flutter --version`)
- Android Studio or VS Code with Flutter/Dart extensions
- USB cable for connecting your physical device
- Git repository with your project code
- Android SDK installed

## 1. Running on an Android Phone (Debug Mode)

Debug mode allows you to test your app on a physical device while connected to your development machine. This enables real-time debugging, hot reload, and console logging.

### Step 1: Prepare Your Android Device

1. Enable Developer Options:
   - Go to **Settings** → **About Phone**
   - Tap **Build Number** 7 times until you see "You are now a developer"

2. Enable USB Debugging:
   - Go to **Settings** → **System** → **Developer Options**
   - Toggle on **USB Debugging**

3. Connect your device:
   - Connect your Android phone to your computer with a USB cable
   - When prompted on your phone, allow USB debugging

### Step 2: Verify Device Connection

```bash
# List connected devices
flutter devices
```

You should see your Android device listed. If not, check your USB connection and debugging settings.

### Step 3: Run the App in Debug Mode

Navigate to your project directory in the terminal:

```bash
# Navigate to your project folder
cd path/to/adhd_assistant

# Get dependencies
flutter pub get

# Run the app on your connected device
flutter run
```

This will:
- Build the app in debug mode
- Install it on your connected device
- Start the app automatically
- Establish a debug connection for hot reload

### Tips for Debug Mode Testing

- **Hot Reload**: Press `r` in your terminal to reload code changes
- **Hot Restart**: Press `R` to restart the app with code changes
- **Quit**: Press `q` to quit the debug session
- **View Logs**: Check terminal for print statements and errors

## 2. Running on a Local Emulator

Emulators are useful when you don't have a physical device or want to test on different screen sizes and Android versions.

### Using Android Studio

#### Step 1: Set Up an Emulator

1. Open Android Studio
2. Click **Tools** → **AVD Manager** (Android Virtual Device Manager)
3. Click **Create Virtual Device**
4. Select a device definition (e.g., Pixel 6)
5. Select a system image (e.g., Android 13)
6. Configure AVD settings and click **Finish**

#### Step 2: Launch the Emulator

1. In the AVD Manager, click the **play** button next to your emulator
2. Wait for the emulator to fully boot up

#### Step 3: Run Your App

**Method 1: Using Android Studio**
1. Open your Flutter project in Android Studio
2. Select the emulator from the device dropdown in the toolbar
3. Click the **Run** button or press `Shift+F10`

**Method 2: Using Terminal**
```bash
# List available emulators
flutter emulators

# Start an emulator
flutter emulators --launch <emulator_id>

# Run the app
flutter run
```

### Using VS Code

#### Step 1: Set Up the Emulator
1. Use Android Studio's AVD Manager as described above to create an emulator

#### Step 2: Run in VS Code
1. Open your project in VS Code
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
3. Type and select "Flutter: Launch Emulator"
4. Select your emulator from the list
5. Once the emulator is running, click **Run** → **Start Debugging** or press `F5`

## 3. Building a Production APK for Sideloading

Sideloading allows you to install your app on devices without using the Play Store, which is perfect for personal use or distributing to a limited audience.

### Step 1: Configure App Settings

1. Update `android/app/build.gradle` with your app details:
   ```gradle
   defaultConfig {
       applicationId "com.yourdomain.adhd_assistant"
       minSdkVersion 21
       targetSdkVersion 33
       versionCode 1
       versionName "1.0.0"
   }
   ```

2. Update app icons in `android/app/src/main/res/mipmap`

3. Set your app name in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application
       android:label="ADHD Assistant"
       ...
   ```

### Step 2: Build a Release APK

```bash
# Navigate to your project folder
cd path/to/adhd_assistant

# Build a release APK
flutter build apk --release
```

The APK will be created at:
`build/app/outputs/flutter-apk/app-release.apk`

For a smaller APK split by architecture:
```bash
flutter build apk --split-per-abi --release
```

This creates separate APKs for different CPU architectures:
- `app-armeabi-v7a-release.apk` (older devices)
- `app-arm64-v8a-release.apk` (newer devices)
- `app-x86_64-release.apk` (emulators)

### Step 3: Sideload the APK

#### Method 1: Transfer and Install Manually

1. Copy the APK file to your Android device:
   - Connect your device via USB and transfer the file
   - Upload to Google Drive and download on your device
   - Send as an email attachment to yourself
   - Use a file transfer app like Send Anywhere

2. On your Android device:
   - Navigate to the APK location
   - Tap the APK file
   - If prompted, allow installations from unknown sources
   - Follow on-screen instructions to install

#### Method 2: Install Directly from Development Machine

```bash
# Install on connected device
flutter install
```

This will install the release version on your connected device.

### Step 4: Testing Your Production Build

Once installed:
1. Verify the app launches correctly
2. Test all major features
3. Check performance and responsiveness
4. Verify APIs connect properly
5. Test background behavior and notifications

## Common Issues and Solutions

### Device Not Detected

**Problem**: Flutter doesn't recognize your connected device

**Solutions**:
- Try a different USB cable or port
- Restart your device and computer
- Run `adb devices` to check if Android Debug Bridge detects your device
- Install/update device drivers on your computer
- Revoke and re-authorize USB debugging permissions on your device

### App Crashes on Start

**Problem**: App installs but crashes immediately

**Solutions**:
- Check your error logs with `adb logcat`
- Verify API endpoints and connectivity settings
- Ensure all dependencies are correctly configured
- Try clearing app data or reinstalling

### Performance Issues

**Problem**: App runs slowly or uses excessive resources

**Solutions**:
- Run Flutter Performance Profiler to identify bottlenecks
- Verify you're using the release build (`--release` flag)
- Check for memory leaks using DevTools
- Review and optimize network requests
- Use the Flutter Performance overlay (`flutter run --profile --trace-skia`)

### API Connection Issues

**Problem**: App cannot connect to your backend

**Solutions**:
- Verify correct API URL for production build
- Check network permissions in the manifest
- Ensure you're handling HTTP/HTTPS properly
- Implement proper error handling for connection issues
- Add offline support for critical functionality

## Advanced Deployment Options

### Enable Multidex (For large apps)

If your app has many dependencies, you might need to enable multidex support:

1. Add to `android/app/build.gradle`:
   ```gradle
   android {
       defaultConfig {
           multiDexEnabled true
       }
   }
   
   dependencies {
       implementation 'androidx.multidex:multidex:2.0.1'
   }
   ```

2. Update your `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application
       android:name="androidx.multidex.MultiDexApplication"
       ...
   ```

### Configure Firebase Crashlytics (For crash reporting)

1. Add dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^2.14.0
     firebase_crashlytics: ^3.3.3
   ```

2. Initialize in `main.dart`:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     
     // Enable crashlytics in release mode
     if (kReleaseMode) {
       FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
     }
     
     runApp(MyApp());
   }
   ```

## Final Checklist

Before distributing your app:

- [ ] Update app version in `pubspec.yaml`
- [ ] Ensure all API endpoints are configured for production
- [ ] Test on multiple device sizes and Android versions
- [ ] Verify app permissions are properly configured
- [ ] Test offline functionality
- [ ] Remove any debug code or hard-coded credentials
- [ ] Optimize app size with `flutter build apk --release --obfuscate --split-debug-info=build/debug`
- [ ] Create a backup of your final APK
- [ ] Document your build process for future updates
