# GRASS-MASTER.md
## Project brief for OpenCode Desktop — offline Android 3D grass-cutting game

**Project directory:** `D:\grass-master`  
**Working style:** one step at a time; do not begin the next step until the user explicitly approves it.  
**Budget:** zero. Prefer free and open-source tools/assets. Never purchase subscriptions, assets, plugins, or services.  
**Primary deliverable:** a playable Android APK for the user's own device.

---

## 1. Mission and important boundaries

Build an original, polished, stylized 3D lawn-mowing game inspired by the broad gameplay loop of *Grass Master – Cutting Game*: guide a mower through colorful vegetation, cut different plant types, complete level objectives, earn progression rewards, and enjoy satisfying visual/audio feedback.

The user wants a very similar *genre and experience*, plus:
- Every implemented level selectable from the start.
- Unlimited coins/resources and all implemented mower upgrades available.
- No in-app purchases, ads, account, analytics, tracking, cloud save, or online requirement.
- A Creative/Relax mode with no timer, no fail state, and no hazards.
- Normal/Challenge mode with objectives and optional timers.
- Adjustable mower speed, cutting radius, cutting power, camera zoom, sound, vibration, and difficulty.
- Responsive touch controls, smooth camera, good-looking 3D environments, clean UI, and reliable local save.
- Android APK export and real-device testing.

**IP boundary:** do not decompile, copy, extract, or reuse the original game's code, proprietary models, textures, sounds, UI artwork, level layouts, branding, name, or other protected assets. Do not bypass its paid unlocks or modify its APK. Create new code, original level layouts, original UI, and original or permissively licensed assets. Use the title **Grass Master** only as a temporary internal project label; before any public release, choose a distinct name and original icon/branding.

**Quality promise:** never claim “zero bugs” or “guaranteed privacy.” Instead, build and test carefully, report limitations honestly, and fix reproducible issues before moving on.

---

## 2. Reference material

The `image/` folder contains original concept references made for this project:
- `reference_scene.png` — visual direction for a bright, cheerful garden.
- `gameplay_hud_mockup.png` — illustrative gameplay HUD concept.
- `upgrade_ui_concept.png` — illustrative garage/upgrades concept.

These are references, not finished game assets. The coding agent must not treat them as exact screenshots of the commercial game. Use them to guide an original visual style.

Public gameplay description reference:
https://play.google.com/store/apps/details?id=com.grass.cut.game

The store description describes mowing different grass/flower/shrub types, level-specific cutting objectives, mower growth/speed progression, boosters, smooth controls, and satisfying ASMR-like feedback. Re-create only the broad genre mechanics using original implementation and assets.

---

## 3. Required workflow — approval gate after EVERY step

This is mandatory.

1. Work on **one numbered step only**.
2. Inspect the current project before changing anything. Do not overwrite existing user files without inspecting and explaining the change.
3. Explain the plan briefly, then implement only the current step.
4. Run the relevant checks for that step. Capture actual command output; never claim a command passed unless it ran successfully.
5. Summarize changed/created files, tests, known issues, and the exact next step.
6. **STOP. Ask the user for explicit permission before starting the next numbered step.**
7. Do not continue just because a command succeeds, because the user is silent, or because a checklist says the next step is ready. Wait for a clear response such as “Approve Step 2” or “পরের ধাপে যাও”.
8. If a step fails, remain on that step, diagnose and fix it, rerun checks, then report the result. Ask permission before advancing.
9. Never run multiple future steps “for convenience.” Do not create the whole game in one huge operation.
10. Keep `PROJECT_STATUS.md` up to date at the end of each completed step, including current step, decisions, files changed, test evidence, known issues, and next-step proposal. Updating this status file is part of the current step, not permission to begin the next step.

### First response to this file
Start with **Step 0: environment and project inspection only**. Do not install anything, create the game, or modify existing files yet. Inspect the folder, available disk space, Windows version, installed Godot/Unity if any, Java/JDK, Android SDK, Git, and available graphics/CPU/RAM details using safe read-only commands. Then propose the simplest free toolchain and ask for permission to proceed to Step 1.

---

## 4. Recommended technology and dependency policy

### Preferred engine
Use **Godot 4.x stable** with **GDScript** for a fully original 3D game, if the current Windows environment supports it. Godot is free/open-source and can export Android builds. Verify the current official Godot documentation before choosing exact version numbers or Android export requirements:
- https://godotengine.org/
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

Do not assume Godot, Java, Android SDK, export templates, or command-line tools are installed. Check first.

### Free dependency policy
- Prefer Godot built-in nodes and APIs.
- Prefer original procedural geometry/materials and CC0 or clearly permissively licensed assets.
- Keep a `THIRD_PARTY_ASSETS.md` file with source URL, license, author, and local path for every third-party asset.
- Avoid paid assets, paid APIs, subscription-only services, ad networks, analytics SDKs, online accounts, and cloud dependencies.
- Do not download random executables or run unknown scripts from the internet.
- Before downloading or installing dependencies, identify the official source, purpose, approximate size, and whether administrator rights are needed. The user has authorized installing necessary free dependencies, but the agent must still stop at each step boundary and ask permission before the next step.
- Never expose API keys or secrets in project files.
- Use a reproducible, documented setup. Pin or record tool versions after confirming them.

If Godot Android export requires OpenJDK and Android SDK command-line tools, install/configure only the verified required components. Do not silently accept SDK licenses or make system-wide changes without telling the user what will happen. If an interactive license or administrator approval is required, pause for the user's action.

### Suggested folder layout (adapt only after approval)
```text
D:\grass-master\
  GRASS-MASTER.md
  PROJECT_STATUS.md
  THIRD_PARTY_ASSETS.md
  project.godot
  project/
    scenes/
    scripts/
    materials/
    models/
    audio/
    ui/
    levels/
    shaders/
  tests/
  build/
  image/
    reference_scene.png
    gameplay_hud_mockup.png
    upgrade_ui_concept.png
  README.md
```

Keep generated builds and caches out of source control where appropriate. Do not create a web app, React wrapper, Capacitor shell, or fake screenshot-only prototype as a substitute for a real 3D game.

---

## 5. Feature specification

### A. Core 3D gameplay
- A third-person/isometric-follow camera with adjustable zoom and a clear view of the mower and nearby plants.
- Smooth 8-direction or analog movement using touch joystick and/or swipe controls; desktop keyboard controls for development.
- Stable mower movement, sensible acceleration, turning, and collision response.
- Procedurally or manually authored garden arenas with clear boundaries.
- Several original vegetation types: short grass, tall grass, colorful flowers, small shrubs, and larger trim-able plants.
- Each plant type has a visible state before and after cutting.
- Cutting detection must be reliable and efficient. Avoid one expensive physics query per blade/plant every frame when a spatial grid, area query, or batched approach will work.
- Satisfying clipping particles, subtle mower vibration, soft audio, and clear visual feedback. Effects must be adjustable and must not overload lower-end phones.
- The mower can visually grow or upgrade as objectives progress, but scaling must not break collisions, camera framing, or controls.
- Pause/resume, restart level, level complete, and level selection flows.
- Smooth transitions; no unskippable long animations.

### B. Modes
1. **Creative / Relax:** no timer, no fail state, no hazards; all plants can be cut freely.
2. **Normal:** level objectives and optional timer.
3. **Challenge:** optional harder objectives; never require ads, purchases, or an online service.

### C. Unlocks and resources
- All implemented levels are selectable from the first launch.
- Coins/resources start at a very large capped value or use an explicit unlimited-resource mode; display `∞` where appropriate.
- All implemented mower types, skins, upgrades, and boosters are unlocked locally.
- Speed, cutting radius, blade power, and booster duration can be adjusted from Settings.
- No payment buttons, store checkout, rewarded ads, premium currency purchase, or paywall.
- Unlock rules must be implemented in the new game's own source code; do not modify the commercial game's APK or copy its private data.
- Keep gameplay configurable and stable: clamp extreme values to safe ranges so the player cannot accidentally launch off the map, break physics, or crash the game.

### D. Levels and progression
- Create original levels with distinct layouts, plant palettes, objectives, and difficulty.
- Start with a small vertical slice (one polished test level), then add more levels only after the core loop works.
- Use data-driven level definitions so adding levels does not require duplicating the gameplay code.
- Level selection must show all levels and their mode/objective summary.
- Save best completion time and optional statistics locally; these must never be required for unlocks.

### E. UI / visual design
- Bright, polished, friendly 3D art direction with lush grass, clear color contrast, soft shadows, readable text, restrained glow, and satisfying cut/uncut contrast.
- Main menu: Play, Level Select, Garage, Creative Mode, Settings, Credits.
- In-game HUD: level name, objective progress, pause, optional timer, and optional resource display.
- Garage: mower preview, mower selection, upgrade sliders/toggles, all-unlocked labels.
- Settings: master/music/SFX volume, vibration, camera zoom/sensitivity, graphics quality, language if practical, and reset-save option.
- Mobile-first landscape layout; adapt to notches/safe areas and different aspect ratios.
- Large touch targets and readable UI at common Android resolutions.
- Avoid copying the commercial game's exact layout, iconography, or visual identity.

### H. App icon, launcher branding, and Android assets
- Create an original, polished app icon for this new game. Do not copy the commercial game's icon or branding.
- Use `image/app_icon_concept.png` as visual inspiration only; inspect it before use. Recreate or adapt the design into a clean icon asset that remains legible at small sizes. Do not blindly use an icon containing tiny text if it becomes unreadable at launcher size.
- The icon should feature a distinctive green mower and lush grass with a strong silhouette, bright friendly colors, and no third-party logo. Choose a distinct final app title before any public release.
- Generate the correct Android launcher icon assets using the chosen engine's supported export workflow, including adaptive icon foreground/background where supported, and required density variants. Do not manually guess Android resource paths; verify them against current official documentation.
- Set the Android application name and package/application ID to project-specific values. Use a clearly documented provisional ID until the user approves the final app name; do not leave a generic template name such as “Godot Game.”
- Verify the icon appears correctly in the installed APK's launcher, app drawer, recent-apps screen, and app info where applicable. Check cropping/masking on Android adaptive icons and ensure key artwork stays inside a safe area.
- Keep the source image and any derived editable/exported assets in the project. Document which assets are concept-only versus used in the build.
- Add icon work to the implementation plan after the basic game skeleton exists and before the final Android export. Do not jump ahead of the current approved step.

### F. Offline and privacy requirements
- The entire game must work after installation with Airplane Mode enabled, including first launch, level selection, gameplay, settings, and save/load.
- Do not include network code, web requests, remote configuration, telemetry, analytics, ad SDKs, social SDKs, account systems, or third-party trackers.
- Do not request Internet, location, contacts, microphone, camera, or unrelated permissions.
- Review the exported Android manifest and final APK permissions; document any unavoidable engine-related permission and remove it if not required and safe to remove.
- All game state is stored locally. Use robust save versioning, defaults, and corruption recovery.
- Provide a local save reset option. Do not collect or upload any personal data.
- Test offline behavior; do not merely assume it works because no networking code was intentionally written.

### G. Performance and reliability
- Aim for stable play on the user's HONOR BVL-AN00 device, while first confirming its GPU/Android details are not accessible from the Windows build environment and asking the user to test on their phone when ready.
- Provide Low/Medium/High graphics options if practical.
- Use LOD/instancing or MultiMesh for large amounts of vegetation where appropriate.
- Pool short-lived particle effects where useful.
- Avoid expensive per-frame work and unbounded node creation.
- Handle pause/resume, screen rotation policy, app backgrounding, and interrupted saves.
- No fabricated “test passed” reports. Save test commands and outputs or explain manual checks.

---

## 6. Step-by-step implementation plan

### Step 0 — Read-only environment and project inspection
- Inspect `D:\grass-master` and existing files.
- Check available disk space, Windows version, RAM/CPU/GPU where possible.
- Detect Godot, Git, Java/JDK, Android SDK, Android build tools, and export templates.
- Check internet access only to determine whether official free downloads are reachable; do not download yet.
- Recommend the simplest compatible free toolchain and estimate required disk space.
- Create no project files and install nothing in this step.
- Report findings and ask permission to proceed to Step 1.

### Step 1 — Prepare the free development environment
- After approval, install/configure only the missing required free tools from official sources.
- Verify versions and Android export setup.
- If installation needs administrator permission, an interactive license, or a significant download, explain and pause for confirmation.
- Run a minimal engine/version check.
- Update `PROJECT_STATUS.md`; stop and ask permission for Step 2.

### Step 2 — Create the clean Godot project skeleton
- Create project configuration, folders, input actions, rendering defaults, landscape-friendly viewport settings, and a basic startup scene.
- Do not yet implement the full game.
- Run the project and confirm no startup errors.
- Stop and ask permission for Step 3.

### Step 3 — Build the first playable 3D garden
- Create one original low-poly/stylized garden using procedural meshes/materials or licensed assets.
- Add ground, boundaries, a few plant types, lighting, sky, and a simple mower placeholder.
- Confirm the scene renders correctly and remains performant.
- Stop and ask permission for Step 4.

### Step 4 — Mower controls and camera
- Implement smooth movement, turning, collision, mobile touch controls, desktop test controls, and follow camera.
- Test map boundaries and camera framing.
- Stop and ask permission for Step 5.

### Step 5 — Grass cutting and visual feedback
- Implement plant states, reliable cutting detection, clipping particles, and basic sound hooks.
- Add counters and clear visual feedback.
- Test that plants cannot be cut repeatedly for duplicate rewards.
- Stop and ask permission for Step 6.

### Step 6 — Core game loop and objectives
- Add objective tracking, level completion, restart, pause, and resume.
- Create one polished level configuration and validate all completion states.
- Stop and ask permission for Step 7.

### Step 7 — Unlocks, unlimited resources, and Creative Mode
- Implement all-level access, unlimited resources, all implemented upgrades unlocked, safe configurable mower strength, and Creative/Relax mode.
- Test persistence and extreme setting values.
- Stop and ask permission for Step 8.

### Step 8 — Menus, garage, settings, and save system
- Create original main menu, level select, garage, HUD, pause screen, settings, local save/load, reset save, and error recovery.
- Test UI layout on multiple aspect ratios and large text.
- Stop and ask permission for Step 9.

### Step 9 — Art, animation, audio, app icon, and polish
- Create the original app icon and launcher/adaptive icon assets using `image/app_icon_concept.png` as a reference; verify the icon at small sizes and on Android.
- Improve mower model, plant variety, grass materials, lighting, particles, animations, transitions, sound design, and haptics where supported.
- Check licensing of every imported asset and record it in `THIRD_PARTY_ASSETS.md`.
- Stop and ask permission for Step 10.

### Step 10 — Add original levels and content
- Add a sensible initial set of varied original levels with distinct goals and vegetation combinations.
- Verify every level is selectable and completable in its intended mode.
- Stop and ask permission for Step 11.

### Step 11 — Automated checks and privacy audit
- Run editor/import checks and any available automated tests.
- Inspect project files for network calls, analytics, ad SDKs, secrets, suspicious dependencies, and unintended permissions.
- Check local-save corruption recovery and app lifecycle behavior.
- Document results and unresolved risks honestly.
- Stop and ask permission for Step 12.

### Step 12 — Android export and device test
- Configure Android export and create a debug APK first.
- Install it on the user's device only after the user agrees to the installation/testing procedure.
- Test first launch, offline play with Airplane Mode, touch controls, UI safe areas, save/load, app resume, performance, and crash behavior.
- Fix issues before making a release build.
- Stop and ask permission for Step 13.

### Step 13 — Final build and handover
- Create a release APK if the environment permits.
- Explain signing and backup of the signing key; never expose or upload it.
- Verify the final APK file exists and report its actual size, version, and test status.
- Provide build/rebuild instructions, project structure, dependency versions, limitations, and known issues.
- Do not claim Google Play readiness unless its separate requirements have actually been checked.

---

## 7. Definition of done

The project is only considered complete when:
- The Android APK installs and launches on the target device.
- Core gameplay is playable with touch controls.
- Grass and plant cutting, objectives, completion, restart, pause, and resume work.
- All implemented levels/upgrades are unlocked and unlimited resources work as designed.
- Creative Mode is available.
- The game functions in Airplane Mode after installation.
- The original app icon and app name appear correctly on the Android launcher and app info screen.
- No unnecessary permissions or network/tracking SDKs remain.
- Local save/load and corruption recovery have been tested.
- The project has been checked for obvious runtime errors and performance issues.
- All third-party assets and licenses are documented.
- Actual test results and remaining limitations are provided.

Do not mark any item complete without evidence.

---

## 8. Communication style

The user prefers short, incremental work rather than huge batches. Communicate in simple Bangla, while code, filenames, identifiers, and technical commands remain in English.

At the end of each step, use this format:

**Step N completed**
- **Files changed:** ...
- **Checks actually run:** ...
- **Result:** ...
- **Known issues:** ...
- **Next proposed step:** Step N+1 — ...
- **Permission required:** “May I proceed to Step N+1?”

Then STOP and wait.
