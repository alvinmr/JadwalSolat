import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let onBack: () -> Void

    @State private var testNotificationSent = false
    private let accentColor = Color(red: 16/255, green: 130/255, blue: 85/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Kembali")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
                // Invisible spacer to center title
                Text("Kembali")
                    .font(.system(size: 13))
                    .hidden()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Calculation Method
                    settingsSection("METODE PERHITUNGAN") {
                        Picker("", selection: $settings.calculationMethod) {
                            ForEach(CalculationMethod.allCases) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(methodDescription)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Location
                    settingsSection("LOKASI") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(LocationMode.allCases, id: \.rawValue) { mode in
                                Button(action: { settings.locationMode = mode }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: settings.locationMode == mode ? "largecircle.fill.circle" : "circle")
                                            .font(.system(size: 14))
                                            .foregroundColor(settings.locationMode == mode ? accentColor : .secondary)
                                        Text(mode.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            if settings.locationMode == .manual {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Nama Kota / Daerah")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    TextField("Contoh: Jakarta, Indonesia", text: $settings.manualCity)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 13))
                                }
                                .padding(.leading, 22)
                                .padding(.top, 4)
                            }
                        }
                    }

                    // MARK: - Menu Bar Display
                    settingsSection("TAMPILAN MENU BAR") {
                        Picker("", selection: $settings.menuBarFormat) {
                            ForEach(MenuBarFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: - General
                    settingsSection("UMUM") {
                        HStack {
                            Text("Koreksi Hijriyah")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                            Stepper(value: $settings.hijriyahOffset, in: -5...5) {
                                Text("\(settings.hijriyahOffset > 0 ? "+" : "")\(settings.hijriyahOffset) hari")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Toggle(isOn: $settings.launchAtLogin) {
                            Text("Launch at Login")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                        }
                        .toggleStyle(.checkbox)
                        .tint(accentColor)
                    }

                    // MARK: - Notification Test
                    settingsSection("NOTIFIKASI") {
                        Button(action: {
                            testNotificationSent = true
                            NotificationService.shared.sendTestNotification()
                            // Reset feedback after 4 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                testNotificationSent = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: testNotificationSent ? "checkmark.circle.fill" : "bell.badge")
                                    .font(.system(size: 14))
                                    .foregroundColor(testNotificationSent ? .green : accentColor)
                                Text(testNotificationSent ? "Terkirim! Cek notifikasi..." : "Uji Notifikasi")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(testNotificationSent ? .green : .primary)
                            }
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut, value: testNotificationSent)

                        Text("Kirim notifikasi percobaan dalam 3 detik untuk memastikan sistem berfungsi.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .frame(width: 300, height: 480)
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.06))
            )
        }
    }

    private var methodDescription: String {
        let m = settings.calculationMethod
        switch m {
        case .kemenagRI: return "Sesuai standar Kementerian Agama Republik Indonesia"
        case .mwl: return "Muslim World League (Liga Muslim Dunia)"
        case .isna: return "Islamic Society of North America (ISNA)"
        case .ummAlQura: return "Umm Al-Qura University, Makkah"
        case .egyptian: return "Egyptian General Authority of Survey"
        }
    }
}
