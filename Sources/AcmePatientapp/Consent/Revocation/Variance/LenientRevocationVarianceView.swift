import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient revocation variance.
    final class LenientRevocationVarianceView {
        var code: String
        var label: String
        var summary: String
        var floorValue: String
        var scoreText: String
        var graceDaysText: String
        var source: String
        var name: String
        var ownerIDText: String
        var revision: String
        var statusLabel: String

        init(code: String, label: String, summary: String, floorValue: String, scoreText: String, graceDaysText: String, source: String, name: String, ownerIDText: String, revision: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summary = summary
            self.floorValue = floorValue
            self.scoreText = scoreText
            self.graceDaysText = graceDaysText
            self.source = source
            self.name = name
            self.ownerIDText = ownerIDText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRevocationVarianceView(_ item: LenientRevocationVariance) -> LenientRevocationVarianceView {
        return LenientRevocationVarianceView(
            code: item.code,
            label: item.label,
            summary: item.summary,
            floorValue: String(format: "%.2f", item.floorValue),
            scoreText: String(format: "%.2f", item.score),
            graceDaysText: String(item.graceDays),
            source: Kit.Text.truncate(item.source, limit: 120),
            name: item.name,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 80),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRevocationVarianceViews(_ items: [LenientRevocationVariance]) -> [LenientRevocationVarianceView] {
        var views: [LenientRevocationVarianceView] = []
        for item in items {
            views.append(toLenientRevocationVarianceView(item))
        }
        return views
    }

    static func sumLenientRevocationVarianceView(_ view: LenientRevocationVarianceView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedFloorValue + parsedScore + Double(parsedGraceDays)
    }
}
