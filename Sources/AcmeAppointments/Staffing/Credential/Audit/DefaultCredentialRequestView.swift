import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default credential request.
    final class DefaultCredentialRequestView {
        var code: String
        var title: String
        var visitMinutesText: String
        var reviewerText: String
        var label: String
        var diagnosisCode: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, title: String, visitMinutesText: String, reviewerText: String, label: String, diagnosisCode: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.reviewerText = reviewerText
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCredentialRequestView(_ item: DefaultCredentialRequest) -> DefaultCredentialRequestView {
        return DefaultCredentialRequestView(
            code: item.code,
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 120),
            label: item.label,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCredentialRequestViews(_ items: [DefaultCredentialRequest]) -> [DefaultCredentialRequestView] {
        var views: [DefaultCredentialRequestView] = []
        for item in items {
            views.append(toDefaultCredentialRequestView(item))
        }
        return views
    }

    static func sumDefaultCredentialRequestView(_ view: DefaultCredentialRequestView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedDurationMinutes)
    }
}
