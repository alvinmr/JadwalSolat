import SwiftUI

struct ContentView: View {
    let prayers: [PrayerTime]
    let tomorrowPrayers: [PrayerTime]
    let cityName: String
    let onQuit: () -> Void
    @ObservedObject var notificationPreferences: NotificationPreferences
    @ObservedObject var settings: AppSettings
    let onSettingsChanged: () -> Void

    @State private var showSettings = false

    private let accentColor = Color(red: 16/255, green: 130/255, blue: 85/255)

    var body: some View {
        if showSettings {
            SettingsView(settings: settings) {
                showSettings = false
                onSettingsChanged()
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                PrayerMenuView(
                    prayers: prayers,
                    tomorrowPrayers: tomorrowPrayers,
                    cityName: cityName,
                    notificationPreferences: notificationPreferences,
                    settings: settings
                )

                // Footer: Settings + Quit
                Divider()
                    .padding(.horizontal, 14)

                HStack {
                    Button(action: { showSettings = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 10))
                            Text("Settings")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onQuit) {
                        HStack(spacing: 5) {
                            Image(systemName: "power")
                                .font(.system(size: 10))
                            Text("Quit")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}
