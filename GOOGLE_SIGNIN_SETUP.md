# Google Sign-In Setup (Required for Drive Backup)

## Steps to enable real Google Sign-In:

### 1. Create Google Cloud Project
1. Go to https://console.cloud.google.com
2. Create new project → name it "Veloura"
3. Enable **Google Drive API**

### 2. Create OAuth Credentials
1. APIs & Services → Credentials → Create OAuth Client ID
2. Application type: **Android**
3. Package name: `com.veloura.app`
4. SHA-1: run `keytool -list -v -keystore release.keystore -alias veloura`
5. Download the `google-services.json`

### 3. Add google-services.json
Place the downloaded file at:
```
android/app/google-services.json
```

### 4. Add Google Services plugin (already in build.gradle.kts)
The plugin is already configured. Just add google-services.json and rebuild.

## Without Setup
Without google-services.json, Drive sync shows "Sign-in cancelled" but the app
works perfectly with P2P messaging — Drive is just optional backup.
