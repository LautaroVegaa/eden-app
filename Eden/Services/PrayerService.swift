import Foundation

struct PrayerRequest: Encodable {
    let name: String
    let gender: String
    let struggle: String
    let desire: String
    let freeText: String
    let verseReference: String
    let verseText: String
}

private struct PrayerResponse: Decodable {
    let prayer: String?
    let error: String?
}

enum PrayerServiceError: LocalizedError {
    case server
    case empty

    var errorDescription: String? {
        switch self {
        case .server: return "Couldn't reach the prayer service."
        case .empty: return "The prayer came back empty."
        }
    }
}

/// Calls the Eden Worker to generate a prayer. The Worker holds the API key.
struct PrayerService {
    func generatePrayer(_ request: PrayerRequest) async throws -> String {
        var urlRequest = URLRequest(url: AppConfig.prayerEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PrayerServiceError.server
        }

        let decoded = try JSONDecoder().decode(PrayerResponse.self, from: data)
        guard let prayer = decoded.prayer, !prayer.isEmpty else {
            throw PrayerServiceError.empty
        }
        return prayer
    }
}
