import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential claim.
    final class CredentialClaimView {
        var code: String
        var title: String
        var visitMinutesText: String
        var score: String
        var approvedText: String
        var discountText: String
        var refillsText: String
        var patientRef: String
        var graceDays: String
        var statusLabel: String

        init(code: String, title: String, visitMinutesText: String, score: String, approvedText: String, discountText: String, refillsText: String, patientRef: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.score = score
            self.approvedText = approvedText
            self.discountText = discountText
            self.refillsText = refillsText
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialClaimView(_ item: CredentialClaim) -> CredentialClaimView {
        return CredentialClaimView(
            code: item.code,
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            score: String(format: "%.2f", item.score),
            approvedText: "\(item.approved)",
            discountText: String(format: "%.2f", item.discount),
            refillsText: String(item.refills),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialClaimViews(_ items: [CredentialClaim]) -> [CredentialClaimView] {
        var views: [CredentialClaimView] = []
        for item in items {
            views.append(toCredentialClaimView(item))
        }
        return views
    }

    static func sumCredentialClaimView(_ view: CredentialClaimView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore + parsedDiscount
    }
}
