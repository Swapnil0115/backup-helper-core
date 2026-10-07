# Backup Helper Core

The open part of **Backup Helper**, a Mac app for people with years of old phone and computer
backups. It shows, folder by folder, which photos are already in Apple Photos and which exist only
in the backup, then imports the missing ones with the right dates. It works entirely offline.

```
┌──────────── backup-helper-core (this repo, MIT) ────────────┐
│  Data model: backup files, Photos items, dates,              │
│              match results, coverage states                  │
│  Media types: what counts as photo / video / sidecar,        │
│               and what Photos can't import                   │
│  Junk rules: thumbnail caches, app caches, chat stickers     │
│              and link previews, code-project images,         │
│              phone trash, system files, icons                │
└──────────────────────────────────────────────────────────────┘
                              ▲
┌──────────── Backup Helper app (private) ────────────────────┐
│  Scanner · date inference · matching against Photos ·        │
│  coverage reports · import · SwiftUI app                     │
└──────────────────────────────────────────────────────────────┘
```

## Why junk rules matter

Phone backups are mostly not photos. On one real 237 GB, 187,000-file personal backup, about
43,000 files were images or videos. Of those, roughly 8,700 were junk: Android `.thumbnails`
caches, app data under `Android/data`, WhatsApp stickers and link previews, phone trash, and
images inside code projects and Python virtual environments. Showing these next to real photos
buries the photos people care about.

`JunkClassifier` flags them from the path alone (plus pixel size for icons), so it costs nothing
per file:

| Reason | Example |
|---|---|
| Thumbnail cache | `Pictures/.thumbnails/1234.jpg` |
| App cache or app data | `Android/data/<app>/cache/...` (shared media under `Android/media/` is kept) |
| Chat link preview | `WhatsApp/Media/.Links/...` |
| Chat sticker | `WhatsApp Stickers/...` |
| Image inside a code project | `node_modules/`, `site-packages/`, `res/drawable-*/`, or any folder below a `package.json`, `requirements.txt`, `.git`, ... |
| In the phone's trash | `.trashed-1690000000-IMG_1.jpg`, `.trash/` |
| Hidden system file | `._IMG_1.jpg` (macOS AppleDouble files on non-Mac drives) |
| Icon-sized image | longest side under 200 px |

Junk is only a suggestion. The app shows it in its own section and never hides or deletes anything.

## Use it

```swift
.package(url: "https://github.com/Swapnil0115/backup-helper-core.git", branch: "main")
```

```swift
import BackupHelperCore

let reason = JunkClassifier().classify(
    relativePath: "PhoneBackup/Pictures/.thumbnails/1234.jpg",
    kind: .photo, metadata: nil, projectRoots: [])
// reason == .thumbnailCache
```

Requires macOS 13+ and Xcode 15+. Run the tests with `swift test`. There are no dependencies.

## Privacy

See [PRIVACY.md](PRIVACY.md).

## License

MIT, see [LICENSE](LICENSE).
