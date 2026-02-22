import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let onBack: () -> Void

    private let accentColor = Color(red: 13/255, green: 148/255, blue: 136/255)

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
                    .foregroundColor(.white)

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
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // MARK: - Location
                    settingsSection("LOKASI") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(LocationMode.allCases, id: \.rawValue) { mode in
                                Button(action: { settings.locationMode = mode }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: settings.locationMode == mode ? "largecircle.fill.circle" : "circle")
                                            .font(.system(size: 14))
                                            .foregroundColor(settings.locationMode == mode ? accentColor : .white.opacity(0.4))
                                        Text(mode.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            if settings.locationMode == .manual {
                                VStack(alignment: .leading, spacing: 6) {
                                    coordField(label: "Latitude", value: $settings.manualLatitude)
                                    coordField(label: "Longitude", value: $settings.manualLongitude)
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
                        Toggle(isOn: $settings.launchAtLogin) {
                            Text("Launch at Login")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .toggleStyle(.checkbox)
                        .tint(accentColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .frame(width: 300, height: 480)
        .background(Color.black.opacity(0.85))
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
            )
        }
    }

    private func coordField(label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 65, alignment: .leading)
            TextField("", value: value, format: .number.precision(.fractionLength(4)))
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                )
        }
    }

    private var methodDescription: String {
        let m = settings.calculationMethod
        if let isya = m.isyaAngle {
            return "Subuh: \(String(format: "%.1f", m.subuhAngle))°  •  Isya: \(String(format: "%.1f", isya))°"
        } else if let min = m.isyaMinutesAfterMaghrib {
            return "Subuh: \(String(format: "%.1f", m.subuhAngle))°  •  Isya: \(Int(min)) menit setelah Maghrib"
        }
        return ""
    }
}
