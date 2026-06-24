import Foundation
import DeviceCheck
import CryptoKit

/// App Attest client. Proves to the Eden Worker that requests come from a genuine,
/// unmodified instance of this app on real Apple hardware — the real lock against
/// scripted abuse of the public prayer endpoint.
///
/// One time: generate a Secure Enclave key and attest it with Apple (using a
/// server-issued challenge). Per request: sign the request body with an assertion.
/// The Worker verifies the attestation once, then every assertion plus its counter.
///
/// Fail-open by design: if App Attest is unsupported (simulator, older OS) or any
/// step fails, `headers(for:)` returns empty and the request proceeds without them.
/// The Worker is the one that decides whether to REQUIRE attestation, so shipping
/// this client before the Worker enforces it is a safe no-op.
@MainActor
final class AppAttestService {
    static let shared = AppAttestService()

    private let service = DCAppAttestService.shared
    private let keyIdKeychainKey = "eden.appattest.keyId"

    private init() {}

    var isSupported: Bool { service.isSupported }

    /// Attestation headers for a Worker request body. Empty when unsupported or on
    /// any failure — never throws into the caller's request path.
    func headers(for body: Data) async -> [String: String] {
        guard service.isSupported else { return [:] }
        do {
            let keyId = try await attestedKeyId()
            let hash = Data(SHA256.hash(data: body))
            let assertion = try await service.generateAssertion(keyId, clientDataHash: hash)
            return [
                "X-Eden-Attest-Key": keyId,
                "X-Eden-Attest-Assertion": assertion.base64EncodedString(),
            ]
        } catch {
            return [:]
        }
    }

    /// A key id that has been attested with Apple, creating and attesting one on
    /// first use and caching the id in the Keychain (so it survives reinstalls).
    private func attestedKeyId() async throws -> String {
        if let existing = KeychainStore.read(keyIdKeychainKey) { return existing }

        let keyId = try await service.generateKey()
        let challenge = try await fetchChallenge()
        let attestation = try await service.attestKey(keyId, clientDataHash: Data(SHA256.hash(data: challenge)))
        try await register(keyId: keyId, attestation: attestation, challenge: challenge)

        KeychainStore.save(keyId, for: keyIdKeychainKey)
        return keyId
    }

    /// One-time server challenge for the attestation, so it cannot be replayed.
    private func fetchChallenge() async throws -> Data {
        var req = URLRequest(url: AppConfig.attestChallengeEndpoint)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
            throw AppAttestError.challenge
        }
        return data
    }

    /// Send the attestation to the Worker, which verifies it (Apple cert chain,
    /// app id, nonce) and stores the public key for future assertion checks.
    private func register(keyId: String, attestation: Data, challenge: Data) async throws {
        var req = URLRequest(url: AppConfig.attestRegisterEndpoint)
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONEncoder().encode([
            "keyId": keyId,
            "attestation": attestation.base64EncodedString(),
            "challenge": challenge.base64EncodedString(),
        ])
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppAttestError.register
        }
    }

    enum AppAttestError: Error { case challenge, register }
}
