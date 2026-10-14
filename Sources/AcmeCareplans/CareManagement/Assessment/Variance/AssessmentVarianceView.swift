import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment variance.
    final class AssessmentVarianceView {
        var codeText: String
        var title: String
        var margin: String
        var region: String
        var archived: String
        var refillsText: String
        var graceDays: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, title: String, margin: String, region: String, archived: String, refillsText: String, graceDays: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.margin = margin
            self.region = region
            self.archived = archived
            self.refillsText = refillsText
            self.graceDays = graceDays
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentVarianceView(_ item: AssessmentVariance) -> AssessmentVarianceView {
        return AssessmentVarianceView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 120),
            margin: String(format: "%.2f", item.margin),
            region: item.region,
            archived: "\(item.archived)",
            refillsText: String(item.refills),
            graceDays: String(item.graceDays),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentVarianceViews(_ items: [AssessmentVariance]) -> [AssessmentVarianceView] {
        var views: [AssessmentVarianceView] = []
        for item in items {
            views.append(toAssessmentVarianceView(item))
        }
        return views
    }

    static func sumAssessmentVarianceView(_ view: AssessmentVarianceView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMargin + Double(parsedRefills) + Double(parsedGraceDays)
    }
}
