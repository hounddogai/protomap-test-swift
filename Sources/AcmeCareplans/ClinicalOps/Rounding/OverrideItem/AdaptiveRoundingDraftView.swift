import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive rounding draft.
    final class AdaptiveRoundingDraftView {
        var code: String
        var labelText: String
        var score: String
        var archived: String
        var sequenceText: String
        var minimum: String
        var updatedAt: String
        var summaryText: String
        var statusLabel: String

        init(code: String, labelText: String, score: String, archived: String, sequenceText: String, minimum: String, updatedAt: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.score = score
            self.archived = archived
            self.sequenceText = sequenceText
            self.minimum = minimum
            self.updatedAt = updatedAt
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRoundingDraftView(_ item: AdaptiveRoundingDraft) -> AdaptiveRoundingDraftView {
        return AdaptiveRoundingDraftView(
            code: item.code,
            labelText: item.label,
            score: String(format: "%.2f", item.score),
            archived: "\(item.archived)",
            sequenceText: String(item.sequence),
            minimum: String(format: "%.2f", item.minimum),
            updatedAt: String(item.updatedAt),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRoundingDraftViews(_ items: [AdaptiveRoundingDraft]) -> [AdaptiveRoundingDraftView] {
        var views: [AdaptiveRoundingDraftView] = []
        for item in items {
            views.append(toAdaptiveRoundingDraftView(item))
        }
        return views
    }

    static func sumAdaptiveRoundingDraftView(_ view: AdaptiveRoundingDraftView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedScore + Double(parsedSequence) + parsedMinimum
    }
}
