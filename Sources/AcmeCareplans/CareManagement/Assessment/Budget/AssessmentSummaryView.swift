import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment summary.
    final class AssessmentSummaryView {
        var code: String
        var label: String
        var channel: String
        var refills: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, channel: String, refills: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channel = channel
            self.refills = refills
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentSummaryView(_ item: AssessmentSummary) -> AssessmentSummaryView {
        return AssessmentSummaryView(
            code: item.code,
            label: item.label,
            channel: item.channel,
            refills: String(item.refills),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentSummaryViews(_ items: [AssessmentSummary]) -> [AssessmentSummaryView] {
        var views: [AssessmentSummaryView] = []
        for item in items {
            views.append(toAssessmentSummaryView(item))
        }
        return views
    }

    static func sumAssessmentSummaryView(_ view: AssessmentSummaryView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
