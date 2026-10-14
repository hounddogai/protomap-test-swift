import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession segment.
    final class AccessionSegmentView {
        var codeText: String
        var labelText: String
        var scoreText: String
        var ceilingText: String
        var patientRefText: String
        var unit: String
        var statusLabel: String

        init(codeText: String, labelText: String, scoreText: String, ceilingText: String, patientRefText: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.scoreText = scoreText
            self.ceilingText = ceilingText
            self.patientRefText = patientRefText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionSegmentView(_ item: AccessionSegment) -> AccessionSegmentView {
        return AccessionSegmentView(
            codeText: item.code,
            labelText: item.label,
            scoreText: String(format: "%.2f", item.score),
            ceilingText: String(format: "%.2f", item.ceiling),
            patientRefText: item.patientRef,
            unit: Kit.Text.truncate(item.unit, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionSegmentViews(_ items: [AccessionSegment]) -> [AccessionSegmentView] {
        var views: [AccessionSegmentView] = []
        for item in items {
            views.append(toAccessionSegmentView(item))
        }
        return views
    }

    static func sumAccessionSegmentView(_ view: AccessionSegmentView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedScore + parsedCeiling
    }
}
