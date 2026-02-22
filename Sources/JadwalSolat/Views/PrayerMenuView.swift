import SwiftUI

struct PrayerMenuView: View {
    let prayers: [PrayerTime]
    let cityName: String
    @ObservedObject var notificationPreferences: NotificationPreferences
    @ObservedObject var settings: AppSettings

    @State private var now = Date()

    // Emerald green accent
    private let accentColor = Color(red: 16/255, green: 130/255, blue: 85/255)
    private let accentLight = Color(red: 34/255, green: 170/255, blue: 115/255)
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            headerSection

            // MARK: - Countdown Card
            countdownCard
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 10)

            // MARK: - Prayer Times List
            prayerTimesList
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
        .frame(width: 300)
        .onReceive(timer) { _ in
            now = Date()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                    Text(cityName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                Text("Jadwal Solat")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(hijriyahDateString)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.white.opacity(0.25))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor, accentLight]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    // MARK: - Hijriyah Date

    private var hijriyahDateString: String {
        let hijri = Calendar(identifier: .islamicUmmAlQura)
        let adjustedDate = Calendar.current.date(byAdding: .day, value: settings.hijriyahOffset, to: now) ?? now
        let components = hijri.dateComponents([.day, .month, .year], from: adjustedDate)
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(target.prayer.timeString)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(accentColor)
                    }

                    Text(countdownText(to: target.prayer))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor.opacity(0.15))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor)
                                .frame(width: geo.size.width * progress, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Prayer Times List

    private var prayerTimesList: some View {
        VStack(spacing: 1) {
            ForEach(prayers, id: \.name) { prayer in
                let isCurrent = isCurrentPrayer(prayer)
                HStack(spacing: 0) {
                    // Left accent indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isCurrent ? accentColor : Color.clear)
                        .frame(width: 3, height: 22)
                        .padding(.trailing, 10)

                    Text(prayer.name.displayName)
                        .font(.system(size: 13, weight: isCurrent ? .bold : .regular, design: .rounded))
                        .foregroundColor(isCurrent ? .primary : .secondary)

                    Spacer()

                    Text(prayer.timeString)
                        .font(.system(size: 13, weight: isCurrent ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isCurrent ? .primary : .secondary)
                        .padding(.trailing, 10)

                    // Bell toggle button
                    Button(action: {
                        notificationPreferences.toggle(prayer.name)
                    }) {
                        Image(systemName: notificationPreferences.isEnabled(prayer.name)
                              ? "bell.fill" : "bell.slash")
                            .font(.system(size: 11))
                            .foregroundColor(notificationPreferences.isEnabled(prayer.name)
                                             ? accentColor : .primary.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCurrent ? accentColor.opacity(0.08) : Color.clear)
                )
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - Logic

    private func isCurrentPrayer(_ prayer: PrayerTime) -> Bool {
        let current = PrayerTime.currentPrayer(from: prayers, at: now)
        return current?.name == prayer.name
    }

    private var countdownTarget: (label: String, prayer: PrayerTime)? {
        guard let next = PrayerTime.nextPrayer(from: prayers, after: now) else { return nil }
        return ("Menuju \(next.name.displayName)", next)
    }

    private func countdownText(to prayer: PrayerTime) -> String {
        let interval = prayer.time.timeIntervalSince(now)
        guard interval > 0 else { return "Menunggu hari esok" }
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
