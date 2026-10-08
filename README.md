# HourBack

HourBack is a small iPhone app that blocks apps until you tap an NFC tag. Tap the tag to turn blocking on. Tap the same tag again to turn it off. Everything stays on the device. There is no account requirement, no schedule, and no server.

This is a cheap, simple alternative to Brick.

## Decisions made without answers

These were not available when the project was created. Change them before you ship.

| Item | Value | Where to change it |
| --- | --- | --- |
| Bundle ID | `com.aauthorizedd.hourback` | `project.yml`, both entitlements files, and `AppConfig.bundleIdentifier` |
| App Group | `group.com.aauthorizedd.hourback` | Both entitlements files and `AppConfig.appGroupIdentifier` |
| Apple Team ID | Not set. There is no paid Apple Developer account yet. | Uncomment `DEVELOPMENT_TEAM` in `project.yml` |
| Support email | `support@REPLACE_ME` | `AppConfig.supportEmail` |
| GitHub repo | [aauthorizedd/Hourback](https://github.com/aauthorizedd/Hourback) | Created from GitHub's setup page, so it is public |

Family Controls, NFC tag reading, Sign in with Apple, and App Groups will not provision until a paid Apple Developer Program membership is on the App ID. Family Controls for the App Store also needs Apple's separate entitlement approval. Development on your own iPhone still needs a team set in `project.yml`.

## Build

Xcode is required. NFC and Screen Time shields do not run in the Simulator. This repo was written on a Mac that did not have Xcode installed, so the iOS target has not been compiled here. The date math in `StatsCalculator` was run on this Mac.

1. Install the latest stable Xcode and open it once so the iOS platform is downloaded.
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). Version 2.46.0 was used here.
3. From this directory, generate the project. Do not hand-edit `HourBack.xcodeproj`. It is gitignored.

```sh
xcodegen generate
open HourBack.xcodeproj
```

4. Set your Development Team on the HourBack and HourBackShield targets, or uncomment `DEVELOPMENT_TEAM` in `project.yml` and regenerate.
5. In the Apple Developer portal, create the App ID `com.aauthorizedd.hourback` and the shield App ID `com.aauthorizedd.hourback.shield`. Enable Family Controls, NFC Tag Reading, Sign in with Apple, and the App Group `group.com.aauthorizedd.hourback`.
6. Run `HourBack` on a physical iPhone. The test scheme is `HourBack`. Unit tests are `HourBackTests` (Product → Test, or Command-U).

Swift language mode is Swift 5. The deployment target is iOS 17.0. There are no third-party packages.

## What the app does

- First launch asks for Screen Time access with `AuthorizationCenter.shared.requestAuthorization(for: .individual)`. If you deny it, the screen explains that and offers Open Settings.
- Settings → Rules opens `FamilyActivityPicker`. Up to 50 apps can be saved. A 51st app is rejected with “You can block up to 50 apps.” The selection is stored on device with SwiftData. While blocking is on, Rules is read-only.
- Settings → Tags pairs up to 3 NFC tags. Pairing reads the tag’s ISO 14443 hardware identifier, stores the SHA-256 hash in Keychain, and shows the tags as Tag 1, Tag 2, and Tag 3. A removed tag renumbers the ones that remain. Tags cannot be removed while blocking is on.
- Home → Scan tag starts an `NFCTagReaderSession` with the prompt “Hold your iPhone near your HourBack tag.” A paired tag turns blocking on or off. An unpaired tag shows “This tag isn’t paired.” If no apps or categories are selected, the scan shows “Choose apps to block in Settings → Rules.” and does not start a session.
- Turning blocking on writes the chosen app tokens to `ManagedSettingsStore.shield.applications` and category tokens to `shield.applicationCategories`. A `BlockSession` is saved in SwiftData and the start time is copied into the App Group. Turning it off clears the shield and stores the end time.
- ManagedSettings keeps the shield up if the app is force-quit or the phone restarts. On launch, HourBack re-applies the saved selection when a session is still open, and clears the shield when no session is open.
- Settings → Emergency Unlock has 5 lifetime uses, stored in Keychain. It ends the current session the same way a tag would, and that time still counts. At zero, the button is replaced by a `mailto:` link to the support email.
- Settings → Account is Sign in with Apple with no backend. The Apple user identifier and the name, if Apple provides one, stay on device. The app works without signing in.
- Activity shows Today, Yesterday, This week, This month, Last month, a 30-day list, and average hours back since the first session. A session that crosses midnight is split across the two calendar days in the current time zone. Durations render as `2h 14m` or `0h 05m`, rounded down to the minute. While blocking is on, Today updates once a minute.

`TagReader` is the NFC seam. `CoreNFCTagReader` is used by the app. `MockTagReader` is used by the Home preview and by `HourBackTests`.

## Capabilities and entitlements

Main app (`HourBack/HourBack.entitlements`):

- Family Controls (`com.apple.developer.family-controls`)
- NFC tag reading (`com.apple.developer.nfc.readersession.formats` = `TAG`)
- Sign in with Apple
- App Group `group.com.aauthorizedd.hourback`

Shield extension (`HourBackShield/HourBackShield.entitlements`):

- Family Controls
- The same App Group

`HourBack/Info.plist`:

- `NFCReaderUsageDescription` = `HourBack uses NFC to read your tag.`
- `com.apple.developer.nfc.readersession.iso7816.select-identifiers` includes `D2760000850101` so an ISO 14443 session can start and the hardware identifier can be read. HourBack does not write tags and does not read NDEF payloads.

There is no Device Activity monitor or report extension.

## Test on an iPhone

Do this on a device with a real NFC tag, after Screen Time access is granted.

- [ ] Fresh install shows “HourBack needs Screen Time access to block apps.” Continue asks for individual Screen Time access. Denying it shows an explanation and Open Settings.
- [ ] Settings → Rules: pick apps. The row reads “Rules · N apps”. Picking a 51st app shows “You can block up to 50 apps.” and does not save that selection.
- [ ] Settings → Tags → Pair a tag. The tag shows up as Tag 1. Pair at most 3.
- [ ] Home → Scan tag with no apps chosen shows “Choose apps to block in Settings → Rules.”
- [ ] Scan a paired tag. Home says Blocking, the square fills in, and opening a chosen app shows a black screen titled HourBack with “This app is blocked. Scan your tag to unlock.”
- [ ] Scan a different, unpaired tag. The only result is “This tag isn’t paired.”
- [ ] Scan the paired tag again. The apps unblock and Activity shows the session.
- [ ] Force-quit HourBack while blocking, then relaunch. It is still blocking, and Today still includes the open session.
- [ ] Restart the iPhone while blocking. The shield is still up.
- [ ] Rules cannot be edited while blocking is on. Removing a tag is refused while blocking is on.
- [ ] Emergency Unlock shows “5 of 5 remaining”, then counts down. Each use ends the session. After 5 uses the button is gone and the support email is a mail link. Delete and reinstall the app: the count should come back only if iCloud Keychain is on (see limitations).
- [ ] A session that runs across midnight counts the before-midnight part on the first day and the rest on the next day.
- [ ] Light mode is white with black type. Dark mode inverts that. Type is Times New Roman. Command-U runs the stats tests.

## Known limitations

- Screen Time shields and NFC need a physical iPhone and a provisioning profile that includes the entitlements above. The Simulator cannot do either.
- Apple deletes an app’s local Keychain items on uninstall (since iOS 10.3). HourBack marks the emergency-unlock counter, tag hashes, and Apple user ID as iCloud-Keychain items (`kSecAttrSynchronizable`) so a reinstall can restore them when iCloud Keychain is enabled. With iCloud Keychain off, a reinstall starts the emergency counter over. That is an Apple platform limit, not something this app can avoid without a server.
- The shield API has no font parameter, so the shield text is black and white with the words from the spec, in the system shield face rather than Times New Roman.
- Websites chosen in the Family Activity picker are ignored. Only apps and categories are shielded.
- There is no background NFC scan and no tag writing.
- Tag labels are their current position. Removing Tag 1 renames the next tag to Tag 1.
- Durations round down to the next lower minute. The Home counter advances once a minute, not once a second.
- Sign in with Apple uses Apple’s required button, which includes the Apple logo. It is the one control that is not a plain text button.
- The account is local only. The CloudKit seam is the comment in `HourBackStore.makeContainer`. It is not implemented.
- No schedules, analytics, backend, or network calls, other than Sign in with Apple talking to Apple and the support `mailto:` link.
