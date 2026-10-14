import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled rounding score.
    final class ScheduledRoundingScoreView {
        var codeText: String
        var nameText: String
        var startsAtText: String
        var unitText: String
        var pinned: String
        var createdAtText: String
        var description: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, nameText: String, startsAtText: String, unitText: String, pinned: String, createdAtText: String, description: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.startsAtText = startsAtText
            self.unitText = unitText
            self.pinned = pinned
            self.createdAtText = createdAtText
            self.description = description
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRoundingScoreView(_ item: ScheduledRoundingScore) -> ScheduledRoundingScoreView {
        return ScheduledRoundingScoreView(
            codeText: item.code,
            nameText: item.name,
            startsAtText: String(item.startsAt),
            unitText: item.unit,
            pinned: "\(item.pinned)",
            createdAtText: String(item.createdAt),
            description: item.description,
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRoundingScoreViews(_ items: [ScheduledRoundingScore]) -> [ScheduledRoundingScoreView] {
        var views: [ScheduledRoundingScoreView] = []
        for item in items {
            views.append(toScheduledRoundingScoreView(item))
        }
        return views
    }

    static func sumScheduledRoundingScoreView(_ view: ScheduledRoundingScoreView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedCreatedAt) + parsedMaximum
    }
}
