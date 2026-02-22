import SwiftUI

struct PrayerMenuView: View {
    let prayers: [PrayerTime]
    let cityName: String
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("Jadwal Solat")
                    .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 12)

            // Prayer times list
            VStack(spacing: 0) {
                ForEach(prayers, id: \.name) { prayer in
                    let isNext = isCurrentPrayer(prayer)
                    HStack {
                        Text(prayer.name.displayName)
                            .fontWeight(isNext ? .semibold : .regular)
                        Spacer()
                        Text(prayer.timeString)
                            .monospacedDigit()
                            .fontWeight(isNext ? .semibold : .regular)
                        if isNext {
                            Text("\u{25C0}")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(isNext ? Color.accentColor.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 12)

            // Footer
            HStack {
                Spacer()
                Button("Quit") {
                    onQuit()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
                .padding(8)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .frame(width: 260)
    }

    private func isCurrentPrayer(_ prayer: PrayerTime) -> Bool {
        let current = PrayerTime.currentPrayer(from: prayers, at: Date())
        return current?.name == prayer.name
    }
}
