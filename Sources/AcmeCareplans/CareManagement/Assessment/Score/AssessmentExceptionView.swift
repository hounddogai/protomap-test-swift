import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment exception.
    final class AssessmentExceptionView {
        var code: String
        var label: String
        var segment: String
        var revisionText: String
        var reviewer: String
        var budget: String
        var ratioText: String
        var floorValueText: String
        var timezone: String
        var graceDays: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, segment: String, revisionText: String, reviewer: String, budget: String, ratioText: String, floorValueText: String, timezone: String, graceDays: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.revisionText = revisionText
            self.reviewer = reviewer
            self.budget = budget
            self.ratioText = ratioText
            self.floorValueText = floorValueText
            self.timezone = timezone
            self.graceDays = graceDays
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentExceptionView(_ item: AssessmentException) -> AssessmentExceptionView {
        return AssessmentExceptionView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            revisionText: String(item.revision),
            reviewer: item.reviewer,
            budget: String(format: "%.2f", item.budget),
            ratioText: String(format: "%.2f", item.ratio),
            floorValueText: String(format: "%.2f", item.floorValue),
            timezone: item.timezone,
            graceDays: String(item.graceDays),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentExceptionViews(_ items: [AssessmentException]) -> [AssessmentExceptionView] {
        var views: [AssessmentExceptionView] = []
        for item in items {
            views.append(toAssessmentExceptionView(item))
        }
        return views
    }

    static func sumAssessmentExceptionView(_ view: AssessmentExceptionView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedRevision) + parsedBudget + parsedRatio
    }
}
