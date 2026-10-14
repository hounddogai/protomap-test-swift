import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive overtime agreement.
    final class AdaptiveOvertimeAgreementView {
        var codeText: String
        var labelText: String
        var attempts: String
        var quantity: String
        var cost: String
        var contactEmail: String
        var patientRefText: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, labelText: String, attempts: String, quantity: String, cost: String, contactEmail: String, patientRefText: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.attempts = attempts
            self.quantity = quantity
            self.cost = cost
            self.contactEmail = contactEmail
            self.patientRefText = patientRefText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveOvertimeAgreementView(_ item: AdaptiveOvertimeAgreement) -> AdaptiveOvertimeAgreementView {
        return AdaptiveOvertimeAgreementView(
            codeText: item.code,
            labelText: item.label,
            attempts: String(item.attempts),
            quantity: String(item.quantity),
            cost: String(format: "%.2f", item.cost),
            contactEmail: item.contactEmail,
            patientRefText: item.patientRef,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveOvertimeAgreementViews(_ items: [AdaptiveOvertimeAgreement]) -> [AdaptiveOvertimeAgreementView] {
        var views: [AdaptiveOvertimeAgreementView] = []
        for item in items {
            views.append(toAdaptiveOvertimeAgreementView(item))
        }
        return views
    }

    static func sumAdaptiveOvertimeAgreementView(_ view: AdaptiveOvertimeAgreementView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedAttempts) + Double(parsedQuantity) + parsedCost
    }
}
