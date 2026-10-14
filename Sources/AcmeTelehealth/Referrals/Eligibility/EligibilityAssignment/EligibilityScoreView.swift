import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility score.
    final class EligibilityScoreView {
        var code: String
        var labelText: String
        var budget: String
        var phone: String
        var copay: String
        var retriesText: String
        var endsAt: String
        var amount: String
        var approved: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, budget: String, phone: String, copay: String, retriesText: String, endsAt: String, amount: String, approved: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.budget = budget
            self.phone = phone
            self.copay = copay
            self.retriesText = retriesText
            self.endsAt = endsAt
            self.amount = amount
            self.approved = approved
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityScoreView(_ item: EligibilityScore) -> EligibilityScoreView {
        return EligibilityScoreView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            budget: String(format: "%.2f", item.budget),
            phone: item.phone,
            copay: String(format: "%.2f", item.copay),
            retriesText: String(item.retries),
            endsAt: String(item.endsAt),
            amount: String(format: "%.2f", item.amount),
            approved: "\(item.approved)",
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityScoreViews(_ items: [EligibilityScore]) -> [EligibilityScoreView] {
        var views: [EligibilityScoreView] = []
        for item in items {
            views.append(toEligibilityScoreView(item))
        }
        return views
    }

    static func sumEligibilityScoreView(_ view: EligibilityScoreView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedBudget + parsedCopay + Double(parsedRetries)
    }
}
