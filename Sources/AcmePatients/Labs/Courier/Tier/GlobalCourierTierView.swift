import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global courier tier.
    final class GlobalCourierTierView {
        var code: String
        var title: String
        var notesText: String
        var timezone: String
        var updatedAt: String
        var weightText: String
        var channel: String
        var sourceText: String
        var score: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, notesText: String, timezone: String, updatedAt: String, weightText: String, channel: String, sourceText: String, score: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notesText = notesText
            self.timezone = timezone
            self.updatedAt = updatedAt
            self.weightText = weightText
            self.channel = channel
            self.sourceText = sourceText
            self.score = score
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCourierTierView(_ item: GlobalCourierTier) -> GlobalCourierTierView {
        return GlobalCourierTierView(
            code: item.code,
            title: item.title,
            notesText: item.notes,
            timezone: item.timezone,
            updatedAt: String(item.updatedAt),
            weightText: String(format: "%.2f", item.weight),
            channel: item.channel,
            sourceText: Kit.Text.truncate(item.source, limit: 80),
            score: String(format: "%.2f", item.score),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCourierTierViews(_ items: [GlobalCourierTier]) -> [GlobalCourierTierView] {
        var views: [GlobalCourierTierView] = []
        for item in items {
            views.append(toGlobalCourierTierView(item))
        }
        return views
    }

    static func sumGlobalCourierTierView(_ view: GlobalCourierTierView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedUpdatedAt) + parsedWeight + parsedScore
    }
}
