# INK

**Private. Fast. Yours.**

INK is a privacy-first mobile browser built with Flutter. It ships with a distinctive manga/ink aesthetic, SearXNG search by default, strong ad & tracker blocking, secure DNS helpers, background downloads, and zero telemetry.

Unlike mainstream browsers that monetize your attention, INK is designed so **you** stay in control.

## Why INK is better for privacy than Google Chrome

| Feature | Google Chrome | INK |
|---------|---------------|-----|
| Default search | Google (tracks you) | SearXNG (no tracking) |
| Built-in ad blocking | Limited / paid | Strong, on by default |
| Tracker blocking | Partial | Dedicated list, on by default |
| Telemetry | Heavy | None |
| Account requirement | Encouraged | Never |
| Open source | Partial | Fully open |
| Design philosophy | Engagement | Privacy + speed |

## Features

- **SearXNG search** — type anything that isn’t a URL and it goes to a privacy-respecting metasearch engine
- **Ad & tracker blocking** — human-auditable domain lists you can edit
- **Secure DNS helpers** — DoH lookup tool + one-tap jump to Android Private DNS
- **Incognito / clear-on-exit**
- **Biometric app lock** (optional)
- **Force HTTPS**, force dark mode on sites, block popups
- **Background downloads** with pause/resume and notifications
- **Manga-ink UI** — bold borders, paper texture, crimson accents
- **Tabs, history, settings** — everything you expect, nothing you don’t

## Quick start

```bash
# Clone / extract
cd ink

# Get dependencies
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Run on device / emulator
flutter run
```

### Building a release APK (local)

Because the `android/` folder is generated on the fly (see below):

```bash
flutter create --platforms=android --org com.ink.browser --project-name ink .
python3 scripts/patch_manifest.py
flutter build apk --release --split-per-abi
```

Or just push to `main` — GitHub Actions builds the APK automatically.

## Project layout

```
ink/
├── assets/
│   ├── adblock/          # Editable blocklists
│   ├── branding/         # Icons & logo
│   └── start/home.html   # Beautiful built-in start page (about:ink)
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── scripts/patch_manifest.py
└── .github/workflows/build_apk.yml
```

## Configuring SearXNG

Any non-URL text in the address bar is sent to your SearXNG instance.

- **Runtime:** Settings → Search → “SearXNG search URL”
- **Default for new installs:** edit `defaultSearxngUrl` in `lib/utils/constants.dart`

Self-hosting SearXNG (Docker) is the gold standard. Public instances work too.

## Secure DNS

Android WebView uses the system network stack. INK therefore:

1. Offers an in-app DoH diagnostic tool
2. Deep-links you straight into Android’s **Private DNS** settings so *all* apps (including INK) use encrypted DNS

Recommended hosts: `1.1.1.1`, `dns.quad9.net`, `dns.adguard-dns.com`

## Ad & tracker blocking

Blocking uses `flutter_inappwebview` ContentBlockers driven by two plain-text lists:

- `assets/adblock/ad_domains.txt`
- `assets/adblock/tracker_domains.txt`

Add one domain per line. Toggle each list independently in Settings. The lists shipped with INK are intentionally readable and effective against the majority of commercial ads and analytics.

## Philosophy

INK has no built-in parental controls or content filtering by design. It is a tool for people who want full control over their own browsing. You are responsible for complying with the laws that apply to you.

## License

MIT
