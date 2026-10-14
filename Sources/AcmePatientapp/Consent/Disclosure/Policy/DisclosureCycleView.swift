import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure cycle.
    final class DisclosureCycleView {
        var codeText: String
        var title: String
        var score: String
        var pinnedText: String
        var retriesText: String
        var activeText: String
        var statusLabel: String

        init(codeText: String, title: String, score: String, pinnedText: String, retriesText: String, activeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.score = score
            self.pinnedText = pinnedText
            self.retriesText = retriesText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureCycleView(_ item: DisclosureCycle) -> DisclosureCycleView {
        return DisclosureCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            score: String(format: "%.2f", item.score),
            pinnedText: "\(item.pinned)",
            retriesText: String(item.retries),
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureCycleViews(_ items: [DisclosureCycle]) -> [DisclosureCycleView] {
        var views: [DisclosureCycleView] = []
        for item in items {
            views.append(toDisclosureCycleView(item))
        }
        return views
    }

    static func sumDisclosureCycleView(_ view: DisclosureCycleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedScore + Double(parsedRetries)
    }
}
