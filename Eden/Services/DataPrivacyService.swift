import Foundation
import RevenueCat

enum DataPrivacyError: LocalizedError {
    case attestationUnavailable
    case server

    var errorDescription: String? {
        switch self {
        case .attestationUnavailable:
            return "This device could not verify the deletion request. Contact support to complete it."
        case .server:
            return "Eden couldn't delete your cloud data right now. Try again or contact support."
        }
    }
}

/// Deletes the anonymous server-side records Eden can associate with this
/// installation. Local prayers remain on-device until the user deletes the app.
@MainActor
struct DataPrivacyService {
    func deleteCloudData() async throws {
        let body = try JSONEncoder().encode([
            "appUserId": Purchases.shared.appUserID,
        ])
        let headers = await AppAttestService.shared.headers(for: body)
        guard !headers.isEmpty else { throw DataPrivacyError.attestationUnavailable }

        var request = URLRequest(url: AppConfig.dataDeletionEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = body
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DataPrivacyError.server
        }
        AppAttestService.shared.resetLocalRegistration()
    }
}
