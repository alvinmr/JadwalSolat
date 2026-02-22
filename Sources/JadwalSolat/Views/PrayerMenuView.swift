import SwiftUI

struct PrayerMenuView: View {
    let prayers: [PrayerTime]
    let cityName: String
    @ObservedObject var notificationPreferences: NotificationPreferences

    @State private var now = Date()

    private let accentColor = Color(red: 13/255, green: 148/255, blue: 136/255) // #0D9488 teal
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            headerSection

            // MARK: - Countdown Card
            countdownCard
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)

            // MARK: - Prayer Times List
            prayerTimesList
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

        }
        .frame(width: 300)
        .onReceive(timer) { _ in
            now = Date()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundColor(accentColor)
                Text(cityName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Image(systemName: "moon.stars")
                    .font(.caption2)
                    .foregroundColor(accentColor)
            }

            Text("Jadwal Solat")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text(hijriyahDateString)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Hijriyah Date

    private var hijriyahDateString: String {
        let hijri = Calendar(identifier: .islamicUmmAlQura)
        let components = hijri.dateComponents([.day, .month, .year], from: now)
        let months = ["Muharram", "Safar", "Rabiul Awal", "Rabiul Akhir",
                      "Jumadil Awal", "Jumadil Akhir", "Rajab", "Syaban",
                      "Ramadhan", "Syawal", "Dzulqaidah", "Dzulhijjah"]
        let monthName = months[(components.month ?? 1) - 1]
        return "\(components.day ?? 1) \(monthName) \(components.year ?? 1447)H"
    }

    // MARK: - Countdown Card

    private var countdownCard: some View {
        Group {
            if let target = countdownTarget {
                VStack(spacing: 8) {
                    HStack {
                        Text(target.label)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(target.prayer.timeString)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Text(countdownText(to: target.prayer))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(accentColor)
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Prayer Times List

    private var prayerTimesList: some View {
        VStack(spacing: 2) {
            ForEach(prayers, id: \.name) { prayer in
                let isCurrent = isCurrentPrayer(prayer)
                HStack(spacing: 0) {
                    // Left accent indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isCurrent ? accentColor : Color.clear)
                        .frame(width: 3, height: 20)
                        .padding(.trailing, 8)

                    Text(prayer.name.displayName)
                        .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isCurrent ? .white : .white.opacity(0.8))

                    Spacer()

                    Text(prayer.timeString)
                        .font(.system(size: 13, weight: isCurrent ? .semibold : .regular, design: .monospaced))
                        .foregroundColor(isCurrent ? .white : .white.opacity(0.7))
                        .padding(.trailing, 8)

                    // Bell toggle button
                    Button(action: {
                        notificationPreferences.toggle(prayer.name)
                    }) {
                        Image(systemName: notificationPreferences.isEnabled(prayer.name)
                              ? "bell.fill" : "bell.slash")
                            .font(.system(size: 11))
                            .foregroundColor(notificationPreferences.isEnabled(prayer.name)
                                             ? accentColor : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCurrent ? accentColor.opacity(0.15) : Color.clear)
                )
            }
        }
    }

    // MARK: - Logic

    private func isCurrentPrayer(_ prayer: PrayerTime) -> Bool {
        let current = PrayerTime.currentPrayer(from: prayers, at: now)
        return current?.name == prayer.name
    }

    private var countdownTarget: (label: String, prayer: PrayerTime)? {
        let maghrib = prayers.first { $0.name == .maghrib }
        let isya = prayers.first { $0.name == .isya }
        let imsak = prayers.first { $0.name == .imsak }

        if let maghrib, now < maghrib.time {
            return ("Berbuka dalam", maghrib)
        } else if let isya, now < isya.time {
            return ("Isya dalam", isya)
        } else if let imsak {
            return ("Imsak dalam", imsak)
        }
        return nil
    }

    private func countdownText(to prayer: PrayerTime) -> String {
        let interval = prayer.time.timeIntervalSince(now)
        guard interval > 0 else { return "Sudah masuk" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours) jam \(minutes) menit"
        }
        return "\(minutes) menit"
    }

    private var progress: Double {
        guard let current = PrayerTime.currentPrayer(from: prayers, at: now),
              let next = PrayerTime.nextPrayer(from: prayers, after: now) else { return 0 }
        let total = next.time.timeIntervalSince(current.time)
        let elapsed = now.timeIntervalSince(current.time)
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }
}
