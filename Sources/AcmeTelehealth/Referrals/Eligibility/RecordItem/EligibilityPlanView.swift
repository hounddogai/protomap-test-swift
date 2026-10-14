import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility plan.
    final class EligibilityPlanView {
        var codeText: String
        var title: String
        var discountText: String
        var patientRef: String
        var attempts: String
        var amountText: String
        var externalRef: String
        var clinicianID: String
        var statusLabel: String

        init(codeText: String, title: String, discountText: String, patientRef: String, attempts: String, amountText: String, externalRef: String, clinicianID: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.discountText = discountText
            self.patientRef = patientRef
            self.attempts = attempts
            self.amountText = amountText
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityPlanView(_ item: EligibilityPlan) -> EligibilityPlanView {
        return EligibilityPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 40),
            discountText: String(format: "%.2f", item.discount),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            attempts: String(item.attempts),
            amountText: String(format: "%.2f", item.amount),
            externalRef: item.externalRef,
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityPlanViews(_ items: [EligibilityPlan]) -> [EligibilityPlanView] {
        var views: [EligibilityPlanView] = []
        for item in items {
            views.append(toEligibilityPlanView(item))
        }
        return views
    }

    static func sumEligibilityPlanView(_ view: EligibilityPlanView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedDiscount + Double(parsedAttempts) + parsedAmount
    }
}
