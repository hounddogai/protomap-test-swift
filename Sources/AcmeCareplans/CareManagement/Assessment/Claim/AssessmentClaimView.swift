import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment claim.
    final class AssessmentClaimView {
        var code: String
        var labelText: String
        var acuityText: String
        var endsAt: String
        var contactEmail: String
        var title: String
        var expiresAt: String
        var margin: String
        var statusLabel: String

        init(code: String, labelText: String, acuityText: String, endsAt: String, contactEmail: String, title: String, expiresAt: String, margin: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.acuityText = acuityText
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.title = title
            self.expiresAt = expiresAt
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentClaimView(_ item: AssessmentClaim) -> AssessmentClaimView {
        return AssessmentClaimView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            acuityText: String(item.acuity),
            endsAt: String(item.endsAt),
            contactEmail: item.contactEmail,
            title: item.title,
            expiresAt: String(item.expiresAt),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentClaimViews(_ items: [AssessmentClaim]) -> [AssessmentClaimView] {
        var views: [AssessmentClaimView] = []
        for item in items {
            views.append(toAssessmentClaimView(item))
        }
        return views
    }

    static func sumAssessmentClaimView(_ view: AssessmentClaimView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedEndsAt) + Double(parsedExpiresAt)
    }
}
