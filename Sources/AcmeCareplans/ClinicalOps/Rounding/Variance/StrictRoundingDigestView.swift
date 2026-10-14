import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict rounding digest.
    final class StrictRoundingDigestView {
        var code: String
        var titleText: String
        var score: String
        var sourceText: String
        var threshold: String
        var externalRef: String
        var approved: String
        var facility: String
        var active: String
        var statusLabel: String

        init(code: String, titleText: String, score: String, sourceText: String, threshold: String, externalRef: String, approved: String, facility: String, active: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.score = score
            self.sourceText = sourceText
            self.threshold = threshold
            self.externalRef = externalRef
            self.approved = approved
            self.facility = facility
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRoundingDigestView(_ item: StrictRoundingDigest) -> StrictRoundingDigestView {
        return StrictRoundingDigestView(
            code: item.code,
            titleText: item.title,
            score: String(format: "%.2f", item.score),
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            externalRef: item.externalRef,
            approved: "\(item.approved)",
            facility: item.facility,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRoundingDigestViews(_ items: [StrictRoundingDigest]) -> [StrictRoundingDigestView] {
        var views: [StrictRoundingDigestView] = []
        for item in items {
            views.append(toStrictRoundingDigestView(item))
        }
        return views
    }

    static func sumStrictRoundingDigestView(_ view: StrictRoundingDigestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedScore + parsedThreshold
    }
}
