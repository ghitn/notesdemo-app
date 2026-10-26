# NotesApp (iOS)

iOS version of the Android NotesApp. Like the Android app, it is a thin shell: one full-screen web view that opens the notes web page. Login, notes, the AI assistant and voice all live in the web service, not in the app.

| Android | iOS (this repo) |
|---|---|
| `MainActivity.kt` `startUrl` | `NOTES_START_URL` in `project.yml` -> `NotesStartURL` in `App/Info.plist` -> `AppConfig.swift` |
| `WebView` + `activity_main.xml` | `WKWebView` in `WebViewModel.swift`, shown by `WebView.swift` / `ContentView.swift` |
| `INTERNET` | no permission needed on iOS |
| `RECORD_AUDIO` | `NSMicrophoneUsageDescription` + media-capture delegate in `WebViewModel.swift` |
| `usesCleartextTraffic="true"` | `NSAppTransportSecurity` (`NSAllowsLocalNetworking`, `NSAllowsArbitraryLoadsInWebContent`) |
| Back button -> `goBack()` | swipe back/forward gestures |
| JavaScript, DOM storage, inline media | JavaScript (default), persistent data store, `allowsInlineMediaPlayback` |

The Android manifest had no camera or storage permission, so none were added.

## Get the IPA
1. Push this repo to GitHub (branch `main`). The workflow `Build unsigned IPA` runs on every push to `main`, or run it by hand from **Actions -> Build unsigned IPA -> Run workflow** (you can type a different start URL there).
2. When it finishes, open the run and download the artifact **unsigned-ipa**. It contains `unsigned.ipa`.

The workflow runs `xcodegen generate`, then `xcodebuild` with code signing off, copies the `.app` into `Payload/`, zips it to `unsigned.ipa` and uploads it.

## Install with Sideloadly
1. Install Sideloadly on your PC/Mac and plug in the iPhone (trust the computer).
2. Drag `unsigned.ipa` into Sideloadly, enter your Apple ID, press Start.
3. On the iPhone: Settings -> General -> VPN & Device Management -> trust your Apple ID. Turn on Developer Mode if iOS asks (Settings -> Privacy & Security).

A free Apple ID signs the app for 7 days. After that, re-run Sideloadly to refresh it.

## The start URL (important)
The iPhone cannot use `localhost` the way the Android emulator did. `adb reverse` does not exist for iPhones, so `localhost` would mean the phone itself. Use one of these:

- **Same Wi-Fi:** the default is `http://192.168.0.106:8092/...` (the PC's address when this was written; check it with `ipconfig`). The PC must be on, the service running, and Windows Firewall must allow port 8092. The first launch asks for Local Network permission.
- **Public https address** (a hosted deployment or a tunnel): set it in `project.yml` (`NOTES_START_URL`) or type it into the workflow's `start_url` box.

**Microphone:** iOS web views only allow the microphone on secure pages (https). Over plain `http://192.168...` the page loads and works, but voice will most likely be refused. For voice, use an https address.

## Build locally (Mac only)
```
brew install xcodegen
xcodegen generate
open NotesApp.xcodeproj
```
`NotesApp.xcodeproj` is generated and not committed.

## Notes
- Requires iOS 16.0 or later.
- There is no app icon yet (iOS shows a blank one); add an `Assets.xcassets` with an `AppIcon` set to get one.
- This was written on Windows and has not been compiled or run on a Mac. The first GitHub Actions run is the first real build.
