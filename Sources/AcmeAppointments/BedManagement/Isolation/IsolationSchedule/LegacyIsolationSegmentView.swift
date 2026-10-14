import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy isolation segment.
    final class LegacyIsolationSegmentView {
        var code: String
        var title: String
        var sourceText: String
        var summary: String
        var segmentText: String
        var bedText: String
        var attempts: String
        var category: String
        var limit: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, title: String, sourceText: String, summary: String, segmentText: String, bedText: String, attempts: String, category: String, limit: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sourceText = sourceText
            self.summary = summary
            self.segmentText = segmentText
            self.bedText = bedText
            self.attempts = attempts
            self.category = category
            self.limit = limit
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyIsolationSegmentView(_ item: LegacyIsolationSegment) -> LegacyIsolationSegmentView {
        return LegacyIsolationSegmentView(
            code: item.code,
            title: item.title,
            sourceText: Kit.Text.truncate(item.source, limit: 120),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            segmentText: item.segment,
            bedText: item.bed,
            attempts: String(item.attempts),
            category: item.category,
            limit: String(item.limit),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyIsolationSegmentViews(_ items: [LegacyIsolationSegment]) -> [LegacyIsolationSegmentView] {
        var views: [LegacyIsolationSegmentView] = []
        for item in items {
            views.append(toLegacyIsolationSegmentView(item))
        }
        return views
    }

    static func sumLegacyIsolationSegmentView(_ view: LegacyIsolationSegmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAttempts) + Double(parsedLimit)
    }
}
