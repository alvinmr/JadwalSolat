# Jadwal Solat Ramadhan — macOS Menu Bar App

## Overview

Native macOS menu bar app yang menampilkan jadwal solat Ramadhan dengan countdown ke waktu solat berikutnya. Deteksi lokasi otomatis, perhitungan lokal tanpa API eksternal.

## Requirements

- Tampilan di menu bar: `🕌 Maghrib 17:58 (23m)` — nama solat berikutnya + waktu + countdown
- Dropdown menampilkan semua waktu solat hari ini (Imsak, Subuh, Dzuhur, Ashar, Maghrib, Isya)
- Deteksi lokasi otomatis via CoreLocation
- Notifikasi macOS native saat waktu solat tiba
- Metode perhitungan: Kemenag RI
- Menu bar-only app (tidak muncul di dock)

## Architecture

### Tech Stack

- Swift 5.9+, SwiftUI
- macOS 13+ (Ventura)
- CoreLocation, UserNotifications
- No external dependencies

### Calculation Method (Kemenag RI)

| Waktu   | Formula                              |
|---------|--------------------------------------|
| Imsak   | Subuh - 10 menit                     |
| Subuh   | Sun angle -20°                       |
| Dzuhur  | Solar noon                           |
| Ashar   | Shadow = object length + noon shadow |
| Maghrib | Sun angle -0.8333°                   |
| Isya    | Sun angle -18°                       |

### Menu Bar Display

```
🕌 Maghrib 17:58 (23m)
```

Updates every minute.

### Dropdown Menu

```
┌─────────────────────────────┐
│  📍 Denpasar, Bali          │
│  📅 Ramadhan 1447H          │
│ ─────────────────────────── │
│  Imsak       04:18          │
│  Subuh       04:28          │
│  Dzuhur      12:05          │
│  Ashar       15:22          │
│  Maghrib     17:58  ◀       │
│  Isya        19:10          │
│ ─────────────────────────── │
│  ⚙ Settings...              │
│  ✕ Quit                     │
└─────────────────────────────┘
```

### Project Structure

```
JadwalSolat/
├── JadwalSolatApp.swift          # Entry point, menu bar setup
├── Models/
│   ├── PrayerTime.swift          # Prayer time model
│   └── PrayerCalculator.swift    # Astronomical calculations
├── Views/
│   └── PrayerMenuView.swift      # Dropdown menu content
├── Services/
│   ├── LocationService.swift     # CoreLocation wrapper
│   └── NotificationService.swift # Notification scheduling
└── Info.plist                    # LSUIElement = true
```

### Location

- CoreLocation for automatic detection
- Cache last known location as fallback
- Reverse geocode for city name display

### Notifications

- UNUserNotificationCenter
- Fire notification exactly when prayer time arrives
- Request permission on first launch
