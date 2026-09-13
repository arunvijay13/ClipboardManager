# Clipboard Manager for macOS

Native Swift/SwiftUI menu-bar clipboard manager.

## v0.8

- Launch at Login is enabled automatically on the first launch so Clipboard Manager starts quietly with macOS.
- Launch at Login can be turned on/off from **Settings → General**. The user's choice is remembered.
- Runs as a menu-bar utility; no history window is opened automatically at login.
- Refined native macOS visual design with standard window controls, adaptive materials, and cleaner controls.
- Clean, compact clipboard rows with hover/selection states and image previews.
- Search field is automatically focused when the history opens.
- Click any clipboard item to paste it into the application/cursor that was active before opening Clipboard Manager.
- `Return` also pastes the selected item.
- The selected item is restored to `NSPasteboard` before automatic paste.
- Automatic `⌘V` is sent to the previous application; macOS Accessibility permission may be required.
- Resizable history window with sensible minimum and maximum dimensions.
- Closing the history window only hides it; it does not quit the application.
- Settings remains a separate window.
- Quit is available from the menu-bar menu and via `⌘Q`.
- Text and image history, duplicate text handling, search, deletion, retention and memory limits.
- App-owned clipboard writes are ignored to prevent duplicate image entries.
- Timed retention is enforced against the item's original copy time; changing to 5 Minutes immediately removes items already older than 5 minutes.
- Clipboard polling runs continuously in the common run-loop mode for reliable copy detection.
- Clipboard history is RAM-only and is cleared when the app exits. Launch at Login only controls startup and never persists clipboard contents.

## Keyboard

- `⌘⇧V`: show/hide clipboard history
- `↑` / `↓`: navigate
- `Return`: paste selected item
- `Delete`: delete selected item when search is not editing
- `Esc`: close history
- Click an item: paste into the previous application/cursor

## Automatic paste permission

The app always restores the selected content to `NSPasteboard`. To automatically send `⌘V` to another application, macOS may require Accessibility permission. Grant Clipboard Manager access in:

**System Settings → Privacy & Security → Accessibility**

Without permission, the clipboard item is still restored and can be pasted manually.

## Launch at Login

On the first launch, Clipboard Manager registers itself as a macOS login item so it starts automatically after you sign in. You can disable this from **Settings → General**. If macOS reports that approval is required, approve Clipboard Manager in **System Settings → General → Login Items**.

## Build

```bash
swift test
swift build -c release
./scripts/package.sh
```

The GitHub Actions build produces `ClipboardManager-macOS.zip` containing `ClipboardManager.app`.

## Distribution

For development/testing, the app can be distributed as a ZIP from GitHub Releases. An unsigned build may trigger macOS Gatekeeper on another Mac.

For a polished public release outside the Mac App Store, Apple provides Developer ID signing and notarization. These require Apple Developer Program membership.
