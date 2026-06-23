import SwiftUI
import WidgetKit

private let appGroupID = "group.com.lautarocarignani.eden"
private let widgetKind = "EdenVerseWidget"

struct EdenVerseEntry: TimelineEntry {
    let date: Date
    let reference: String
    let text: String
}

struct EdenVerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> EdenVerseEntry {
        EdenVerseEntry(
            date: Date(),
            reference: "1 Peter 5:7",
            text: "casting all your worries on him, because he cares for you."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EdenVerseEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EdenVerseEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21_600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> EdenVerseEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let reference = defaults?.string(forKey: "eden.widget.verse.reference")
        let text = defaults?.string(forKey: "eden.widget.verse.text")

        return EdenVerseEntry(
            date: Date(),
            reference: reference?.isEmpty == false ? reference! : "1 Peter 5:7",
            text: text?.isEmpty == false ? text! : "casting all your worries on him, because he cares for you."
        )
    }
}

struct EdenVerseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: EdenVerseEntry

    private let cream = Color(red: 0.96, green: 0.94, blue: 0.90)
    private let navy = Color(red: 0.05, green: 0.07, blue: 0.12)
    private let gold = Color(red: 0.88, green: 0.66, blue: 0.33)

    var body: some View {
        switch family {
        case .accessoryRectangular:
            lockScreenView
        case .systemMedium:
            homeView(horizontal: true)
        default:
            homeView(horizontal: false)
        }
    }

    private var lockScreenView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(shortVerse)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
            Text(entry.reference)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private func homeView(horizontal: Bool) -> some View {
        VStack(alignment: .leading, spacing: horizontal ? 10 : 8) {
            HStack(spacing: 6) {
                AppIconCross()
                    .stroke(gold, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 12, height: 12)
                Text("Eden")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(gold)
                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)

            Text("\"\(shortVerse)\"")
                .font(.system(horizontal ? .headline : .subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(navy)
                .lineLimit(horizontal ? 3 : 5)
                .minimumScaleFactor(horizontal ? 0.78 : 0.68)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.reference)
                .font(.caption.weight(.semibold))
                .foregroundStyle(gold)
                .lineLimit(1)
        }
        .padding(horizontal ? 18 : 16)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [cream, Color(red: 0.99, green: 0.97, blue: 0.93)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var shortVerse: String {
        let trimmed = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = family == .systemSmall ? 86 : 132
        guard trimmed.count > limit else { return trimmed }
        let prefix = trimmed.prefix(max(0, limit - 3))
        return prefix.trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

private struct AppIconCross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let centerY = rect.midY
        path.move(to: CGPoint(x: centerX, y: rect.minY))
        path.addLine(to: CGPoint(x: centerX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: centerY))
        path.addLine(to: CGPoint(x: rect.maxX, y: centerY))
        return path
    }
}

struct EdenVerseWidget: Widget {
    let kind = widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EdenVerseProvider()) { entry in
            EdenVerseWidgetView(entry: entry)
        }
        .configurationDisplayName("Eden Verse")
        .description("A verse for what you are carrying today.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

@main
struct EdenWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        EdenVerseWidget()
    }
}
