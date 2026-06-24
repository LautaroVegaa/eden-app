import SwiftUI
import SwiftData
import UIKit

/// Talk to God — a focused prayer-companion chat. Eden replies conversationally
/// and stays in the faith/prayer lane (enforced server-side). Daily message cap
/// protects token cost; the hard paywall gates access to paying users.
struct TalkToGodView: View {
    var onBack: () -> Void = {}

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage(AppConfig.aiConsentKey) private var aiConsentGranted = false
    @StateObject private var speaker = PrayerSpeaker()

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var sending = false
    @State private var remaining = ChatLimiter.dailyLimit
    @State private var pendingAIAction: PendingAIAction?
    @State private var showingAIConsent = false
    @FocusState private var focused: Bool

    private enum PendingAIAction {
        case send(String)
        case listen(String)
    }

    private var profile: UserProfile? { profiles.first }
    private var trimmed: String { input.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var verse: Verse? { VerseStore.shared.verse(for: profile?.struggle ?? "peace") }
    private var canSend: Bool { !trimmed.isEmpty && !sending && remaining > 0 }

    private let suggestions = [
        "I can't sleep, my mind won't stop",
        "I'm scared about the future",
        "I feel far from God",
        "Help me find peace"
    ]

    var body: some View {
        ScreenContainer {
            VStack(spacing: 0) {
                header
                messagesList
                inputBar
            }
        }
        .onAppear { remaining = ChatLimiter.remaining() }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .alert("Allow AI data sharing?", isPresented: $showingAIConsent) {
            Button("Cancel", role: .cancel) { pendingAIAction = nil }
            Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
            Button("Allow") {
                aiConsentGranted = true
                let action = pendingAIAction
                pendingAIAction = nil
                switch action {
                case let .send(text): send(text)
                case let .listen(text): speaker.toggle(text)
                case nil: break
                }
            }
        } message: {
            Text("Eden sends your first name and messages to Anthropic to create replies. Listen sends generated text to OpenAI to create temporary audio. Eden does not store this content on its servers.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    HapticService.selection()
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.86))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Text("Talk to God")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            if let verse {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verse.text)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    Text(verse.reference)
                        .font(.caption)
                        .foregroundStyle(Theme.accentText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if messages.isEmpty { welcome }
                    ForEach(messages) { bubble($0).id($0.id) }
                    if sending { typingBubble.id("typing") }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 12) {
            bubble(ChatMessage(role: .assistant,
                               text: "I'm here with you. Tell me what's on your heart, and we'll bring it to God together."))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button { send(suggestion) } label: {
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Theme.surface, in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.accentFill.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            MedicalDisclaimerText().padding(.top, 6)
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == .user
        return HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.text)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(isUser ? Theme.accentFill.opacity(0.18) : Theme.surface,
                            in: RoundedRectangle(cornerRadius: 16))
                .contextMenu {
                    Button { requestListen(message.text) } label: { Label("Listen", systemImage: "headphones") }
                    Button { UIPasteboard.general.string = message.text } label: { Label("Copy", systemImage: "doc.on.doc") }
                }
            if !isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var typingBubble: some View {
        HStack {
            EdenTypingDots()
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 40)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 6) {
            if remaining <= 0 {
                Text("You've used today's prayers. Come back tomorrow.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            HStack(spacing: 10) {
                TextField("What's on your heart?", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
                    .focused($focused)
                Button { send(trimmed) } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? Theme.accentText : Theme.textMuted)
                }
                .disabled(!canSend)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background)
    }

    private func send(_ text: String) {
        // Chat is a paid feature — present the paywall to non-subscribers.
        guard purchases.requireSubscription() else { return }
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !sending, ChatLimiter.canSend() else {
            remaining = ChatLimiter.remaining()
            return
        }
        guard aiConsentGranted else {
            pendingAIAction = .send(content)
            showingAIConsent = true
            return
        }
        input = ""
        focused = false
        HapticService.impact()
        messages.append(ChatMessage(role: .user, text: content))
        let matchedVerse = VerseStore.shared.verse(for: "\(content) \(profile?.struggle ?? "")")
        WidgetVerseStore.save(reference: matchedVerse?.reference ?? "", text: matchedVerse?.text ?? "")
        ChatLimiter.register()
        remaining = ChatLimiter.remaining()
        sending = true

        let history = messages.suffix(8).map {
            ChatTurn(role: $0.role == .user ? "user" : "assistant", text: $0.text)
        }
        let name = profile?.name ?? ""

        Task {
            do {
                let reply = try await PrayerService().chat(name: name, messages: history)
                messages.append(ChatMessage(role: .assistant, text: reply))
            } catch {
                messages.append(ChatMessage(role: .assistant,
                                            text: "I couldn't respond just now. Check your connection and try again."))
            }
            sending = false
        }
    }

    private func requestListen(_ text: String) {
        guard purchases.requireSubscription() else { return }
        if speaker.isSpeaking {
            speaker.stop()
        } else if aiConsentGranted {
            speaker.toggle(text)
        } else {
            pendingAIAction = .listen(text)
            showingAIConsent = true
        }
    }
}
