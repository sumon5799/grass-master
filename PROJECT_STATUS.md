# Grass Master — Project Status

## Current Status
- **Completed Step:** Step 1 — Prepare the free development environment
- **Next Proposed Step:** Step 2 — Create the clean Godot project skeleton (awaiting user approval)
- **Last Updated:** 2026-10-15

---

## Step History & Decisions

### Step 0 — Read-only environment and project inspection (Completed)
- **Findings:**
  - Environment: Amazon Linux 2023.12 (`Linux 6.18.49 x86_64`), 4 vCPU, 8.2 GiB RAM, 62 GB free disk space.
  - Repository (`sumon5799/grass-master`) initially contained only `GRASS-MASTER.md`.
  - Missing `image/` reference files (`reference_scene.png`, `gameplay_hud_mockup.png`, `upgrade_ui_concept.png`, `app_icon_concept.png`) noted; will create/handle original assets when reaching the corresponding steps.
  - Direct USB/ADB connection to target device (`HONOR BVL-AN00`) is not attached to the cloud VM; signed `.apk` builds will be produced locally in the workspace for the user to install and test on-device.

### Step 1 — Prepare the free development environment (Completed)
- **Decisions:**
  - Selected **Godot Engine 4.3-stable** (`4.3.stable.official.77dcf97d8`) with GDScript as the 100% free, open-source 3D engine.
  - Installed **OpenJDK 17** (`Amazon Corretto 17.0.20.1+10-LTS`) required for Godot 4 Android export and APK signing.
  - Installed **Android SDK Command-Line Tools** (`12.0` / build `11076708`), `platform-tools` (`37.0.1`), `build-tools;34.0.0` (`apksigner 0.9`), and `platforms;android-34`.
  - Installed official **Godot 4.3.stable Export Templates** (`android_debug.apk`, `android_release.apk`, `android_source.zip`) at `/home/vercel-sandbox/.local/share/godot/export_templates/4.3.stable/`.
  - Generated standard Android debug keystore at `/home/vercel-sandbox/.android/debug.keystore` and configured Godot editor settings (`/home/vercel-sandbox/.config/godot/editor_settings-4.3.tres` and `editor_settings-4.tres`) with `android_sdk_path`, `java_sdk_path`, and `debug_keystore`.

---

## Pinned Toolchain Versions & Paths

| Tool / Component | Version | Path / Location | Official Source |
| :--- | :--- | :--- | :--- |
| **Godot Engine** | `4.3.stable.official.77dcf97d8` | `/usr/local/bin/godot4` (`/usr/local/bin/godot`) | `https://github.com/godotengine/godot-builds/releases/download/4.3-stable/` |
| **Godot Export Templates** | `4.3.stable` | `/home/vercel-sandbox/.local/share/godot/export_templates/4.3.stable/` | `https://github.com/godotengine/godot-builds/releases/download/4.3-stable/` |
| **Java / OpenJDK** | `17.0.20.1` (Corretto 17 LTS) | `/usr/lib/jvm/java-17-amazon-corretto.x86_64` | Amazon Linux 2023 official repository (`dnf`) |
| **Android SDK Cmdline Tools** | `12.0` (`11076708_latest`) | `/home/vercel-sandbox/android-sdk/cmdline-tools/latest` | `https://dl.google.com/android/repository/` |
| **Android Platform Tools** | `37.0.1` (`adb 1.0.41`) | `/home/vercel-sandbox/android-sdk/platform-tools` | Google Android SDK Repository |
| **Android Build Tools** | `34.0.0` (`apksigner 0.9`) | `/home/vercel-sandbox/android-sdk/build-tools/34.0.0` | Google Android SDK Repository |
| **Android Platform API** | `android-34` (API 34) | `/home/vercel-sandbox/android-sdk/platforms/android-34` | Google Android SDK Repository |
| **Android Debug Keystore** | PKCS12 RSA-2048 | `/home/vercel-sandbox/.android/debug.keystore` | Generated locally via `keytool` |

---

## Files Changed in Step 1
- `PROJECT_STATUS.md` (created and updated with Step 0 & Step 1 status, pinned versions, and verification outputs)

---

## Test Evidence (Step 1)
1. **Java / JDK Check:**
   - Command: `java -version && javac -version`
   - Result: `openjdk version "17.0.20.1" 2026-08-18 LTS` / `javac 17.0.20.1`
2. **Godot Engine & Headless Smoke Check:**
   - Command: `godot4 --version` -> `4.3.stable.official.77dcf97d8`
   - Command: `godot4 --headless --path /tmp/godot-smoke-test -s check.gd`
   - Result: `Godot headless check OK: 4.3-stable (official)` (exit code 0)
3. **Godot Export Templates Check:**
   - Verified presence of `android_debug.apk` (104 MB), `android_release.apk` (88 MB), `android_source.zip` (176 MB), and `version.txt` (`4.3.stable`).
4. **Android SDK & Build Tools Check:**
   - Command: `sdkmanager --version` -> `12.0`
   - Command: `adb --version` -> `Android Debug Bridge version 1.0.41 (Version 37.0.1-15733141)`
   - Command: `apksigner --version` -> `0.9`
   - Verified `/home/vercel-sandbox/android-sdk/platforms/android-34/android.jar` exists.

---

## Known Issues & Limitations
- Running inside a headless cloud Linux VM without a physical GPU or direct USB link to `HONOR BVL-AN00`. Godot runs in `--headless` mode for script/scene validation and APK export, and the user will test exported APKs directly on their phone.
- Reference images in `image/` (`reference_scene.png`, `gameplay_hud_mockup.png`, `upgrade_ui_concept.png`, `app_icon_concept.png`) are not present in the repository; original assets will be generated/authored during the appropriate steps.

---

## Next Proposed Step
- **Step 2 — Create the clean Godot project skeleton:**
  - Create `project.godot`, `.gitignore`, `THIRD_PARTY_ASSETS.md`, and the clean directory layout (`project/scenes`, `project/scripts`, `project/materials`, `project/models`, `project/audio`, `project/ui`, `project/levels`, `project/shaders`, `tests`, `build`).
  - Configure input actions, rendering defaults (mobile compatibility), landscape viewport settings, and a basic startup scene.
  - Run the project with `godot4 --headless` to confirm zero startup or script errors.
