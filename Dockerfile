# =============================================================
#  Veloura — Flutter APK Builder
#  Multi-stage Dockerfile
#
#  Stages:
#    1. android-base   → Java 17 + Android SDK cmdline-tools
#    2. android-sdk    → build-tools, platform-tools, API 34
#    3. flutter-sdk    → Flutter 3.22.2 stable + precache
#    4. dependencies   → pub get (layer-cached)
#    5. builder        → full build → APKs
#    6. artifact       → tiny image with just the APKs
#
#  Run:
#    docker build -t veloura .
#    docker run --rm -v "$(pwd)/output:/output" veloura
#
#  APKs land in ./output/ on the host.
# =============================================================

# ─────────────────────────────────────────────────────────────
#  STAGE 1 — Java 17 + system deps
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jdk-jammy AS android-base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget unzip git zip xz-utils \
        lib32stdc++6 libstdc++6 libglu1-mesa \
        clang cmake ninja-build pkg-config \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────
#  STAGE 2 — Android SDK
# ─────────────────────────────────────────────────────────────
FROM android-base AS android-sdk

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk

ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/34.0.0:${PATH}"

# Download Android command-line tools
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && wget -q "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
         -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/ct \
    && mv /tmp/ct/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm -rf /tmp/cmdline-tools.zip /tmp/ct

# Accept licenses & install SDK components
RUN yes | sdkmanager --licenses > /dev/null 2>&1 || true \
    && sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "platforms;android-33" \
        "build-tools;33.0.2"

# ─────────────────────────────────────────────────────────────
#  STAGE 3 — Flutter SDK
# ─────────────────────────────────────────────────────────────
FROM android-sdk AS flutter-sdk

ARG FLUTTER_VERSION=3.22.2
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
ENV PUB_CACHE=/root/.pub-cache

# Download Flutter SDK
RUN wget -q \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -O /tmp/flutter.tar.xz \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz

# Pre-warm Flutter (downloads Dart SDK, gradle wrapper, Android artifacts)
RUN flutter config --no-analytics \
    && flutter config --android-sdk "${ANDROID_HOME}" \
    && flutter precache --android \
    && yes | flutter doctor --android-licenses 2>/dev/null || true \
    && flutter doctor -v

# ─────────────────────────────────────────────────────────────
#  STAGE 4 — Dependency cache layer
#  Copying only pubspec first means this layer is only
#  invalidated when dependencies change, not on every code edit.
# ─────────────────────────────────────────────────────────────
FROM flutter-sdk AS dependencies

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# ─────────────────────────────────────────────────────────────
#  STAGE 5 — Full build
# ─────────────────────────────────────────────────────────────
FROM dependencies AS builder

# Copy full source
COPY . .

# Restore pub (in case COPY invalidated something)
RUN flutter pub get

# Hive / Riverpod code generation
RUN flutter pub run build_runner build --delete-conflicting-outputs \
    || echo "[info] build_runner skipped (no generated code yet)"

# Build release APKs — split per ABI + universal
RUN flutter build apk --release \
        --target-platform android-arm,android-arm64 \
        --split-per-abi \
        --obfuscate \
        --split-debug-info=/app/build/debug-info \
    && flutter build apk --release

# Print summary
RUN echo "" \
    && echo "┌──────────────────────────────────────────┐" \
    && echo "│   Veloura APK Build — Complete ✓          │" \
    && echo "└──────────────────────────────────────────┘" \
    && find /app/build/app/outputs/flutter-apk/ -name "*.apk" \
       -exec sh -c 'printf "  %-12s  %s\n" "$(du -sh "$1"|cut -f1)" "$1"' _ {} \;

# ─────────────────────────────────────────────────────────────
#  STAGE 6 — Minimal artifact-only image (~10 MB vs ~4 GB)
# ─────────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS artifact

RUN apt-get update && apt-get install -y --no-install-recommends zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /output

COPY --from=builder /app/build/app/outputs/flutter-apk/*.apk ./
COPY --from=builder /app/build/debug-info ./debug-info/

# Bundle all APKs into a single zip for convenience
RUN zip veloura-release-apks.zip *.apk

CMD ["sh", "-c", \
  "echo '' && echo 'Veloura APK files:' && ls -lh /output/*.apk && echo ''"]
