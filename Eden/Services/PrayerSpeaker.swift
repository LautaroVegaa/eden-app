import AVFoundation

/// On-device text-to-speech (free) for the "Listen" button. Reads your prayer
/// with your eyes closed. Picks the deepest, calmest male voice available and
/// lowers pitch + rate for a grounded, reverent tone.
final class PrayerSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func toggle(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            return
        }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.bestVoice()
        utterance.pitchMultiplier = 0.85          // deeper / graver
        utterance.rate = 0.43                      // slower, calmer
        utterance.preUtteranceDelay = 0.2
        synthesizer.speak(utterance)
    }

    /// Best available English male voice: premium > enhanced > default,
    /// preferring en-US. Higher-quality voices appear once the user downloads
    /// them in iOS Settings → Accessibility → Spoken Content → Voices.
    private static func bestVoice() -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") && $0.gender == .male }

        func score(_ v: AVSpeechSynthesisVoice) -> Int {
            var s = 0
            switch v.quality {
            case .premium: s += 100
            case .enhanced: s += 50
            default: break
            }
            if v.language == "en-US" { s += 10 }
            return s
        }

        return candidates.max { score($0) < score($1) }
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
