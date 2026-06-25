# Veloura — GitHub Push Checklist

## Exact folder structure to push

```
veloura/                              ← ROOT (this whole folder goes to GitHub)
│
├── .github/
│   └── workflows/
│       └── build-apk.yml            ✅ GitHub Actions (auto-builds APK)
│
├── lib/                             ✅ All Flutter source code
│   ├── main.dart
│   ├── core/
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       ├── app_text_styles.dart
│   │       └── app_theme.dart
│   ├── features/
│   │   ├── home/screens/home_screen.dart
│   │   └── splash/screens/splash_screen.dart
│   ├── routes/
│   │   └── app_router.dart
│   └── widgets/
│       ├── glass_card.dart
│       └── particle_background.dart
│
├── android/                         ✅ Android build config
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       └── AndroidManifest.xml
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
│
├── pubspec.yaml                     ✅ Dependencies
├── Dockerfile                       ✅ Docker build system
├── docker-compose.yml               ✅ Docker Compose
├── docker-build.sh                  ✅ Build helper script
├── .dockerignore                    ✅ Docker ignore rules
└── .gitignore                       ✅ Git ignore rules (see below)
```

## Files to NEVER push (add to .gitignore)

```
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
android/local.properties
android/.gradle/
android/app/build/
*.keystore
*.jks
key.properties
output/
.pub-cache/
```
