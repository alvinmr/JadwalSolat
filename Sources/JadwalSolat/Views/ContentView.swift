import SwiftUI

struct ContentView: View {
    let prayers: [PrayerTime]
    let cityName: String
    let onQuit: () -> Void
    @ObservedObject var notificationPreferences: NotificationPreferences
    @ObservedObject var settings: AppSettings
    let onSettingsChanged: () -> Void

    @State private var showSettings = false

    private let accentColor = Color(red: 13/255, green: 148/255, blue: 136/255)

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
                    cityName: cityName,
                    notificationPreferences: notificationPreferences
                )

                // Footer: Settings + Quit
                HStack {
                    Button(action: { showSettings = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gearshape")
                                .font(.caption2)
                            Text("Settings")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onQuit) {
                        HStack(spacing: 4) {
                            Image(systemName: "power")
                                .font(.caption2)
                            Text("Quit")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.black.opacity(0.85))
        }
    }
}
