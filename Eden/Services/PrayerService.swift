import Foundation
import RevenueCat

struct PrayerRequest: Encodable {
    let name: String
    let gender: String
    let struggle: String
    let desire: String
    let freeText: String
    let verseReference: String
    let verseText: String
}

struct ChatTurn: Encodable {
    let role: String
    let text: String
}

private struct ChatRequest: Encodable {
    let name: String
    let messages: [ChatTurn]
    let appUserId: String
}

/// Wire body for a prayer request — the caller's PrayerRequest plus the
/// RevenueCat app user id (so the Worker can verify the subscription).
private struct PrayerWireBody: Encodable {
    let name: String
    let gender: String
    let struggle: String
    let desire: String
    let freeText: String
    let verseReference: String
    let verseText: String
    let appUserId: String

    init(_ r: PrayerRequest, appUserId: String) {
        name = r.name
        gender = r.gender
        struggle = r.struggle
        desire = r.desire
        freeText = r.freeText
        verseReference = r.verseReference
        verseText = r.verseText
        self.appUserId = appUserId
    }
}

private struct PrayerResponse: Decodable {
    let prayer: String?
    let error: String?
}

enum PrayerServiceError: LocalizedError {
    case server
    case empty
    /// 403 from the Worker: free prayer already used, or not subscribed. Not a
    /// retryable error — the caller should move the user on (to the paywall).
    case notAllowed

    var errorDescription: String? {
        switch self {
        case .server: return "Couldn't reach the prayer service."
        case .empty: return "The prayer came back empty."
        case .notAllowed: return "This prayer needs a subscription."
        }
    }
}

/// Calls the Eden Worker to generate a prayer. The Worker holds the API key.
struct PrayerService {
    func generatePrayer(_ request: PrayerRequest) async throws -> String {
        var urlRequest = URLRequest(url: AppConfig.prayerEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 20
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try JSONEncoder().encode(PrayerWireBody(request, appUserId: Purchases.shared.appUserID))
        await attachAttestation(&urlRequest)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw PrayerServiceError.server }
        if http.statusCode == 403 { throw PrayerServiceError.notAllowed }
        guard (200..<300).contains(http.statusCode) else {
            throw PrayerServiceError.server
        }

        let decoded = try JSONDecoder().decode(PrayerResponse.self, from: data)
        guard let prayer = decoded.prayer, !prayer.isEmpty else {
            throw PrayerServiceError.empty
        }
        return prayer
    }

    /// Attach App Attest headers so the Worker can prove the request comes from a
    /// genuine app instance. No-op (and never throws) when unsupported or failing.
    private func attachAttestation(_ request: inout URLRequest) async {
        let headers = await AppAttestService.shared.headers(for: request.httpBody ?? Data())
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    /// Focused prayer-companion chat. Sends the conversation history; the Worker
    /// keeps it in the faith/prayer lane and returns Eden's reply.
    func chat(name: String, messages: [ChatTurn]) async throws -> String {
        var urlRequest = URLRequest(url: AppConfig.prayerEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 20
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try JSONEncoder().encode(
            ChatRequest(name: name, messages: messages, appUserId: Purchases.shared.appUserID)
        )
        await attachAttestation(&urlRequest)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PrayerServiceError.server
        }
        let decoded = try JSONDecoder().decode(PrayerResponse.self, from: data)
        guard let reply = decoded.prayer, !reply.isEmpty else {
            throw PrayerServiceError.empty
        }
        return reply
    }
}
