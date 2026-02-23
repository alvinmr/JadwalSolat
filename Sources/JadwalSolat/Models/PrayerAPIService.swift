import Foundation

struct PrayerAPIService {
    let address: String
    let method: CalculationMethod

    init(address: String, method: CalculationMethod = .kemenagRI) {
        self.address = address
        self.method = method
    }

    func fetch(for date: Date) async throws -> [PrayerTime] {
        let timestamp = Int(date.timeIntervalSince1970)
        
        let safeAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Jakarta"
        // AlAdhan API endpoint using timestamp and address
        guard let url = URL(string: "https://api.aladhan.com/v1/timingsByAddress/\(timestamp)?address=\(safeAddress)&method=\(method.apiMethodId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0 // Fail reasonably quickly if offline
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("API Error: HTTP Status \(code)")
            throw URLError(.badServerResponse)
        }
        
        // Parse JSON
        let decoder = JSONDecoder()
        
        do {
            let apiResponse = try decoder.decode(AlAdhanResponse.self, from: data)
            let timings = apiResponse.data.timings
            let responseDateStr = apiResponse.data.date.gregorian.date // "DD-MM-YYYY"
            let apiTimezoneId = apiResponse.data.meta.timezone // "Asia/Jakarta"
            let apiTimeZone = TimeZone(identifier: apiTimezoneId) ?? TimeZone.current
            
            // We must construct dates in the API's timezone so they reflect the exact local time there
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = apiTimeZone
            
            let dateFormattingParts = responseDateStr.split(separator: "-").compactMap { Int($0) }
            guard dateFormattingParts.count == 3 else { throw URLError(.cannotParseResponse) }
            let day = dateFormattingParts[0]
            let month = dateFormattingParts[1]
            let year = dateFormattingParts[2]
            
            // Helper function to build the final accurate Date
            func makeAccurateDate(_ name: PrayerName, timeString: String) -> PrayerTime? {
                let timePart = timeString.components(separatedBy: " ").first ?? timeString
                let parts = timePart.split(separator: ":").compactMap { Int($0) }
                guard parts.count >= 2 else { return nil }
                
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = day
                components.hour = parts[0]
                components.minute = parts[1]
                components.second = 0
                
                guard let finalDate = calendar.date(from: components) else { return nil }
                return PrayerTime(name: name, time: finalDate)
            }
            
            let prayers = [
                makeAccurateDate(.imsak, timeString: timings.Imsak),
                makeAccurateDate(.subuh, timeString: timings.Fajr),
                makeAccurateDate(.dzuhur, timeString: timings.Dhuhr),
                makeAccurateDate(.ashar, timeString: timings.Asr),
                makeAccurateDate(.maghrib, timeString: timings.Maghrib),
                makeAccurateDate(.isya, timeString: timings.Isha)
            ].compactMap { $0 }
            
            return prayers
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
    }
}

// MARK: - API Response Models

fileprivate struct AlAdhanResponse: Decodable {
    let data: AlAdhanData
}

fileprivate struct AlAdhanData: Decodable {
    let timings: AlAdhanTimings
    let date: AlAdhanDateObj
    let meta: AlAdhanMeta
}

fileprivate struct AlAdhanDateObj: Decodable {
    let gregorian: AlAdhanGregorian
}

fileprivate struct AlAdhanGregorian: Decodable {
    let date: String
}

fileprivate struct AlAdhanMeta: Decodable {
    let timezone: String
}

fileprivate struct AlAdhanTimings: Decodable {
    let Imsak: String
    let Fajr: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
    
    // Ignoring the other extra keys the API returns by just not defining them.
    // Swift's Decodable automatically ignores unmapped keys.
}
