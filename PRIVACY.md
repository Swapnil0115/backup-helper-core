# Privacy

Backup Helper looks at some of people's most personal files, so its privacy claims are designed to
be checked rather than taken on trust.

## What the app reads

- **Backup folders you choose:** file names, sizes and dates, plus each photo's or video's header
  (capture date, time zone, dimensions, duration, camera make and model, Live Photo ID). The grid
  draws thumbnails of these files on your Mac.
- **Your Photos library:** for each item, its original file name, creation date, dimensions,
  duration and Live Photo video name. **No image data is requested from Photos**, and nothing is
  downloaded from iCloud.

## What the app writes

- A scan cache in its own sandbox container, so rescans are fast and unplugged drives can still be
  browsed.
- **Nothing in your backups, ever.** The sandbox gives the app read-only access to the folders you
  pick, so it *cannot* change or delete backup files.
- **Nothing in your Photos library** until you use import, which only adds photos after you confirm.

## What the app sends

Nothing, and you don't have to take the source code's word for it. Most of the app is
closed source, so the guarantee doesn't come from reading code. It comes from the macOS sandbox:

- A sandboxed app can only open network connections if it holds the
  `com.apple.security.network.client` or `network.server` entitlement. Backup Helper holds
  neither, so macOS itself blocks every connection it might try.
- Anyone can check the shipped app:
  ```
  codesign -d --entitlements - "/Applications/Backup Helper.app"
  ```
  There should be no `com.apple.security.network.*` keys. A network monitor such as Little Snitch
  or LuLu will also show no connections.
- Purchases go through macOS's own App Store service, not the app, so even paying needs no network
  access in the app.

One honest caveat: no sandbox stops an app from asking *another* app to open a web link (you
would see it, because your browser opens). Backup Helper never does this. Its only Apple Events
are allowed to the Photos app alone, for "Show in Photos", and that restriction appears in the
same entitlements output.
