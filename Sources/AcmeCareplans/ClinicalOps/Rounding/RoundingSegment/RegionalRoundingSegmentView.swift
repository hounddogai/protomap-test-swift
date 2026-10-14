import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional rounding segment.
    final class RegionalRoundingSegmentView {
        var codeText: String
        var nameText: String
        var limitText: String
        var priority: String
        var graceDays: String
        var attempts: String
        var pinnedText: String
        var statusLabel: String

        init(codeText: String, nameText: String, limitText: String, priority: String, graceDays: String, attempts: String, pinnedText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.limitText = limitText
            self.priority = priority
            self.graceDays = graceDays
            self.attempts = attempts
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRoundingSegmentView(_ item: RegionalRoundingSegment) -> RegionalRoundingSegmentView {
        return RegionalRoundingSegmentView(
            codeText: item.code,
            nameText: item.name,
            limitText: String(item.limit),
            priority: String(item.priority),
            graceDays: String(item.graceDays),
            attempts: String(item.attempts),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRoundingSegmentViews(_ items: [RegionalRoundingSegment]) -> [RegionalRoundingSegmentView] {
        var views: [RegionalRoundingSegmentView] = []
        for item in items {
            views.append(toRegionalRoundingSegmentView(item))
        }
        return views
    }

    static func sumRegionalRoundingSegmentView(_ view: RegionalRoundingSegmentView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedLimit) + Double(parsedPriority) + Double(parsedGraceDays)
    }
}
