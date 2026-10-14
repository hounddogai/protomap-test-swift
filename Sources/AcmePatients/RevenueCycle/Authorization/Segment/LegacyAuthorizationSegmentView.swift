import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a legacy authorization segment.
    final class LegacyAuthorizationSegmentView {
        var code: String
        var title: String
        var diagnosisCodeText: String
        var archived: String
        var startsAt: String
        var sequence: String
        var refills: String
        var quantity: String
        var summary: String
        var score: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCodeText: String, archived: String, startsAt: String, sequence: String, refills: String, quantity: String, summary: String, score: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCodeText = diagnosisCodeText
            self.archived = archived
            self.startsAt = startsAt
            self.sequence = sequence
            self.refills = refills
            self.quantity = quantity
            self.summary = summary
            self.score = score
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAuthorizationSegmentView(_ item: LegacyAuthorizationSegment) -> LegacyAuthorizationSegmentView {
        return LegacyAuthorizationSegmentView(
            code: item.code,
            title: item.title,
            diagnosisCodeText: item.diagnosisCode,
            archived: "\(item.archived)",
            startsAt: String(item.startsAt),
            sequence: String(item.sequence),
            refills: String(item.refills),
            quantity: String(item.quantity),
            summary: item.summary,
            score: String(format: "%.2f", item.score),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAuthorizationSegmentViews(_ items: [LegacyAuthorizationSegment]) -> [LegacyAuthorizationSegmentView] {
        var views: [LegacyAuthorizationSegmentView] = []
        for item in items {
            views.append(toLegacyAuthorizationSegmentView(item))
        }
        return views
    }

    static func sumLegacyAuthorizationSegmentView(_ view: LegacyAuthorizationSegmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedSequence) + Double(parsedRefills)
    }
}
