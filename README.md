# ☪️ Jadwal Solat

A lightweight, native macOS menu bar app for Islamic prayer times — built with Swift & SwiftUI.

Jadwal Solat sits quietly in your menu bar and shows the next prayer time with a live countdown. Click it to see the full schedule in a beautiful popover.

## ✨ Features

- **Menu Bar Countdown** — Always shows the next prayer and remaining time
- **6 Prayer Times** — Imsak, Subuh, Dzuhur, Ashar, Maghrib, Isya
- **Hijriyah Calendar** — Displays the current Islamic date (Umm Al-Qura) with manual offset correction
- **Multiple Calculation Methods** — Kemenag RI, MWL, ISNA, Umm Al-Qura, Egyptian
- **Auto Location (GPS)** or manual latitude/longitude input
- **Per-Prayer Notifications** — Toggle notification bell for each prayer individually
- **Light & Dark Mode** — Adapts seamlessly to your macOS appearance
- **Launch at Login** — Optional auto-start when you log in
- **Customizable Menu Bar** — Choose between full, name+countdown, countdown-only, or time-only display

## 📸 Preview

| Menu Bar | Popover |
|----------|---------|
| ☪️ Ashar (2j 15m) | Emerald header with countdown card & prayer list |

## 🛠 Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+

## 🚀 Build & Run

```bash
# Clone the repo
git clone https://github.com/your-username/JadwalSolat.git
cd JadwalSolat

# Build the app bundle
./scripts/build-app.sh

# Run
open .build/release/JadwalSolat.app

# Or install to Applications
cp -r .build/release/JadwalSolat.app /Applications/
```

## 📁 Project Structure

```
JadwalSolat/
├── Package.swift
├── Sources/JadwalSolat/
│   ├── main.swift                  # App entry point
│   ├── AppDelegate.swift           # Menu bar setup, popover, timers
│   ├── Models/
│   │   ├── AppSettings.swift       # Settings & calculation methods
│   │   ├── PrayerCalculator.swift  # Astronomical prayer time calculations
│   │   └── PrayerTime.swift        # Prayer time model
│   ├── Services/
│   │   ├── LocationService.swift   # GPS location via CoreLocation
│   │   ├── NotificationService.swift
│   │   └── NotificationPreferences.swift
│   └── Views/
│       ├── ContentView.swift       # Main container (menu ↔ settings)
│       ├── PrayerMenuView.swift    # Prayer times popover UI
│       └── SettingsView.swift      # Settings panel
├── Tests/
├── Resources/
├── scripts/
│   └── build-app.sh               # Builds .app bundle
└── docs/
```

## ⚙️ Calculation Methods

| Method | Subuh Angle | Isya |
|--------|-------------|------|
| **Kemenag RI** | 20.0° | 18.0° |
| MWL | 18.0° | 17.0° |
| ISNA | 15.0° | 15.0° |
| Umm Al-Qura | 18.5° | 90 min after Maghrib |
| Egyptian | 19.5° | 17.5° |

## 📄 License

MIT License — feel free to use, modify, and distribute.
