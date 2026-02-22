import Foundation

struct PrayerCalculator {
    let latitude: Double
    let longitude: Double
    let timezone: Double

    // Kemenag RI angles
    private let subuhAngle = 20.0
    private let isyaAngle = 18.0

    func calculate(for date: Date) -> [PrayerTime] {
        let cal = Calendar.current
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)
        let year = cal.component(.year, from: date)

        let d = julianDate(year: year, dayOfYear: dayOfYear)
        let sunDecl = sunDeclination(d: d)
        let eqOfTime = equationOfTime(d: d)

        let transitTime = solarNoon(eqOfTime: eqOfTime)

        let subuhTime = transitTime - hourAngle(angle: subuhAngle, decl: sunDecl) / 15.0
        let dzuhurTime = transitTime
        let asharTime = transitTime + asharHourAngle(decl: sunDecl) / 15.0
        let maghribTime = transitTime + hourAngle(angle: 0.8333, decl: sunDecl) / 15.0
        let isyaTime = transitTime + hourAngle(angle: isyaAngle, decl: sunDecl) / 15.0
        let imsakTime = subuhTime - 10.0 / 60.0

        return [
            makePrayerTime(.imsak, hours: imsakTime, date: date),
            makePrayerTime(.subuh, hours: subuhTime, date: date),
            makePrayerTime(.dzuhur, hours: dzuhurTime, date: date),
            makePrayerTime(.ashar, hours: asharTime, date: date),
            makePrayerTime(.maghrib, hours: maghribTime, date: date),
            makePrayerTime(.isya, hours: isyaTime, date: date),
        ]
    }

    // MARK: - Astronomical Calculations

    private func julianDate(year: Int, dayOfYear: Double) -> Double {
        return 367.0 * Double(year)
            - floor(7.0 * (Double(year) + floor((1.0 + 9.0) / 12.0)) / 4.0)
            + floor(275.0 * 1.0 / 9.0)
            + dayOfYear - 730531.5
    }

    private func sunDeclination(d: Double) -> Double {
        let g = fixAngle(357.529 + 0.98560028 * d)
        let q = fixAngle(280.459 + 0.98564736 * d)
        let l = fixAngle(q + 1.915 * sin(deg2rad(g)) + 0.020 * sin(deg2rad(2 * g)))
        let e = 23.439 - 0.00000036 * d
        return rad2deg(asin(sin(deg2rad(e)) * sin(deg2rad(l))))
    }

    private func equationOfTime(d: Double) -> Double {
        let g = fixAngle(357.529 + 0.98560028 * d)
        let q = fixAngle(280.459 + 0.98564736 * d)
        let l = fixAngle(q + 1.915 * sin(deg2rad(g)) + 0.020 * sin(deg2rad(2 * g)))
        let e = 23.439 - 0.00000036 * d
        let ra = rad2deg(atan2(cos(deg2rad(e)) * sin(deg2rad(l)), cos(deg2rad(l)))) / 15.0
        return q / 15.0 - fixHour(ra)
    }

    private func solarNoon(eqOfTime: Double) -> Double {
        return fixHour(12.0 + timezone - longitude / 15.0 - eqOfTime)
    }

    private func hourAngle(angle: Double, decl: Double) -> Double {
        let cosHA = (sin(deg2rad(-angle)) - sin(deg2rad(latitude)) * sin(deg2rad(decl)))
            / (cos(deg2rad(latitude)) * cos(deg2rad(decl)))
        return rad2deg(acos(cosHA))
    }

    private func asharHourAngle(decl: Double) -> Double {
        let zenithAtNoon = abs(latitude - decl)
        let shadowLength = 1.0 + tan(deg2rad(zenithAtNoon))
        let asharAltitude = rad2deg(atan(1.0 / shadowLength))
        let cosHA = (sin(deg2rad(asharAltitude)) - sin(deg2rad(latitude)) * sin(deg2rad(decl)))
            / (cos(deg2rad(latitude)) * cos(deg2rad(decl)))
        return rad2deg(acos(cosHA))
    }

    // MARK: - Helpers

    private func makePrayerTime(_ name: PrayerName, hours: Double, date: Date) -> PrayerTime {
        let cal = Calendar.current
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60.0)
        var components = cal.dateComponents([.year, .month, .day], from: date)
        components.hour = h
        components.minute = m
        components.second = 0
        return PrayerTime(name: name, time: cal.date(from: components) ?? date)
    }

    private func deg2rad(_ deg: Double) -> Double { deg * .pi / 180.0 }
    private func rad2deg(_ rad: Double) -> Double { rad * 180.0 / .pi }

    private func fixAngle(_ a: Double) -> Double {
        var result = a.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }

    private func fixHour(_ h: Double) -> Double {
        var result = h.truncatingRemainder(dividingBy: 24.0)
        if result < 0 { result += 24.0 }
        return result
    }
}
