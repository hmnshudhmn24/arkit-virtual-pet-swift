# 🐶 ARKit Virtual Pet

Bring a virtual pet into your room! 🐾
This sample app demonstrates an **ARKit + RealityKit** experience where you place a pet (dog, cat, dragon), interact via taps, feed it, throw a ball to play fetch, and control it with voice commands.



## Features

- 📱 Place & interact with a 3D pet in real-world space (plane detection).
- 🎙️ Voice commands using Speech Framework: “sit”, “jump”, “fetch”, “come”.
- 🥎 Mini-game: Throw a ball and pet fetches it.
- 🍖 Feed the pet by pressing the Feed button.
- 🎨 Customizable pets via USDZ models (dog/cat/dragon) — programmatic fallbacks included.
- 🧩 SwiftUI frontend with RealityKit AR view.



## Tech Stack

- Swift 5.8+ / SwiftUI
- ARKit + RealityKit
- Speech framework (on-device speech recognition)
- Xcode 14 / 15 recommended
- iOS 16+ (iOS 17 recommended for best RealityKit improvements)



## Getting started

1. **Create a new Xcode project**
   - Platform: iOS
   - Interface: SwiftUI
   - Life Cycle: SwiftUI App

2. **Add the source files** into your project:
   - `ARKitVirtualPetApp.swift`
   - `ContentView.swift`
   - `ARViewContainer.swift`
   - `PetEntity.swift`
   - `SpeechManager.swift`
   - `GameManager.swift`
   - `Utils.swift`

3. **Add 3D assets (optional)**
   Place your `.usdz` models in the app bundle (Resources) and name them:
   - `pet_dog.usdz`
   - `pet_cat.usdz`
   - `pet_dragon.usdz`
   The app falls back to simple spheres if models are missing.

4. **Add Info.plist keys** (privacy):
   - `NSCameraUsageDescription`
   - `NSMicrophoneUsageDescription`
   - `NSSpeechRecognitionUsageDescription`

5. **Run on a real device** (AR requires a device with ARKit support).



## UX / How to use

- Start the app and scan the environment — follow the coaching overlay to find a horizontal surface.
- Tap anywhere on a detected plane to place your pet.
- Tap the pet to pet it (it will react).
- Use UI controls:
  - **Throw Ball** → spawns a ball that pet will fetch.
  - **Feed** → makes pet perform an "eat" animation.
  - **Voice** → starts speech recognition; say “sit”, “jump”, “fetch”, or “come”.
  - **Fetch** → triggers fetch mini-game.
- Change pet type with the segmented control (Dog / Cat / Dragon).



## Extending the project (ideas)

- ✅ Add proper 3D rigged models (USDZ/Reality Composer exports) with skeletal animations for sit, jump, walk.
- ✅ Use RealityKit physics & collision response for realistic ball throwing.
- ✅ Add persistent pet state (hunger, happiness) stored in Core Data.
- ✅ Add AR recording & sharing so users can export short videos/gifs of their pet.
- ✅ Use on-device ML (CoreML) to predict pet moods or recommend actions.



## Troubleshooting

- **App crashes on launch**: ensure `Info.plist` keys are set and you run on a physical ARKit-capable device.
- **Speech not working**: Check microphone permission and speech recognition authorization.
- **No USDZ models visible**: Confirm `.usdz` files are in the app bundle — otherwise fallback sphere will show.

