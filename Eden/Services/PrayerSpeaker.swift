import AVFoundation
import RevenueCat

/// Plays a prayer read aloud in a warm, deep, calm voice. The audio is generated
/// by the Eden Worker (OpenAI "onyx") and streamed back as mp3 — far more human
/// than on-device text-to-speech. A loading flag covers the brief fetch.
@MainActor
final class PrayerSpeaker: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false

    private var player: AVAudioPlayer?
    private var loadTask: Task<Void, Never>?

    /// Toggle playback: starts fetching + playing, or stops if already active.
    func toggle(_ text: String) {
        if isSpeaking || loadTask != nil {
            stop()
            return
        }
        isSpeaking = true
        loadTask = Task { await loadAndPlay(text) }
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil
        player?.stop()
        player = nil
        isSpeaking = false
    }

    private func loadAndPlay(_ text: String) async {
        defer { loadTask = nil }
        guard let data = await fetchAudio(text), !Task.isCancelled else {
            isSpeaking = false
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            let audio = try AVAudioPlayer(data: data)
            audio.delegate = self
            audio.play()
            player = audio
            isSpeaking = true
        } catch {
            isSpeaking = false
        }
    }

    private func fetchAudio(_ text: String) async -> Data? {
        guard UserDefaults.standard.bool(forKey: AppConfig.aiConsentKey) else { return nil }
        var req = URLRequest(url: AppConfig.ttsEndpoint)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONEncoder().encode([
            "text": text,
            "appUserId": Purchases.shared.appUserID,
        ])
        let headers = await AppAttestService.shared.headers(for: req.httpBody ?? Data())
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }
        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
            return nil
        }
        return data
    }
}

extension PrayerSpeaker: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isSpeaking = false
            self.player = nil
        }
    }
}
