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
    // Stored in UserDefaults (NOT Keychain) on purpose: it is cleared on reinstall,
    // exactly like the underlying Secure Enclave key, so a stale id never points at
    // a key that no longer exists.
    private let keyIdDefaultsKey = "eden.appattest.keyId"

    private init() {}

    var isSupported: Bool { service.isSupported }

    /// Attestation headers for a Worker request body. Empty when unsupported or on
    /// any failure — never throws into the caller's request path.
    func headers(for body: Data) async -> [String: String] {
        guard service.isSupported else { return [:] }
        do {
            return try await signedHeaders(for: body, allowReattest: true)
        } catch {
            return [:]
        }
    }

    private func signedHeaders(for body: Data, allowReattest: Bool) async throws -> [String: String] {
        let keyId = try await attestedKeyId()
        do {
            let hash = Data(SHA256.hash(data: body))
            let assertion = try await service.generateAssertion(keyId, clientDataHash: hash)
            return [
                "X-Eden-Attest-Key": keyId,
                "X-Eden-Attest-Assertion": assertion.base64EncodedString(),
            ]
        } catch {
            // The cached key is no longer usable (its Secure Enclave key was removed,
            // e.g. on reinstall). Drop it and attest a fresh one, once.
            guard allowReattest else { throw error }
            UserDefaults.standard.removeObject(forKey: keyIdDefaultsKey)
            return try await signedHeaders(for: body, allowReattest: false)
        }
    }

    /// A key id that has been attested with Apple. Created and attested on first
    /// use; cached in UserDefaults so its lifetime matches the Secure Enclave key.
    private func attestedKeyId() async throws -> String {
        if let existing = UserDefaults.standard.string(forKey: keyIdDefaultsKey) { return existing }

        let keyId = try await service.generateKey()
        let challenge = try await fetchChallenge()
        let attestation = try await service.attestKey(keyId, clientDataHash: Data(SHA256.hash(data: challenge)))
        try await register(keyId: keyId, attestation: attestation, challenge: challenge)

        UserDefaults.standard.set(keyId, forKey: keyIdDefaultsKey)
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
