import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional outreach segment.
    final class RegionalOutreachSegmentView {
        var code: String
        var title: String
        var score: String
        var patientRefText: String
        var externalRef: String
        var name: String
        var ratioText: String
        var maximum: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, score: String, patientRefText: String, externalRef: String, name: String, ratioText: String, maximum: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.score = score
            self.patientRefText = patientRefText
            self.externalRef = externalRef
            self.name = name
            self.ratioText = ratioText
            self.maximum = maximum
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalOutreachSegmentView(_ item: RegionalOutreachSegment) -> RegionalOutreachSegmentView {
        return RegionalOutreachSegmentView(
            code: item.code,
            title: item.title,
            score: String(format: "%.2f", item.score),
            patientRefText: item.patientRef,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            name: item.name,
            ratioText: String(format: "%.2f", item.ratio),
            maximum: String(format: "%.2f", item.maximum),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalOutreachSegmentViews(_ items: [RegionalOutreachSegment]) -> [RegionalOutreachSegmentView] {
        var views: [RegionalOutreachSegmentView] = []
        for item in items {
            views.append(toRegionalOutreachSegmentView(item))
        }
        return views
    }

    static func sumRegionalOutreachSegmentView(_ view: RegionalOutreachSegmentView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedScore + parsedRatio + parsedMaximum
    }
}
