import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary closure assignment.
    final class PrimaryClosureAssignmentView {
        var code: String
        var titleText: String
        var phoneText: String
        var currency: String
        var acuityText: String
        var amount: String
        var discount: String
        var batchSizeText: String
        var marginText: String
        var statusLabel: String

        init(code: String, titleText: String, phoneText: String, currency: String, acuityText: String, amount: String, discount: String, batchSizeText: String, marginText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.phoneText = phoneText
            self.currency = currency
            self.acuityText = acuityText
            self.amount = amount
            self.discount = discount
            self.batchSizeText = batchSizeText
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryClosureAssignmentView(_ item: PrimaryClosureAssignment) -> PrimaryClosureAssignmentView {
        return PrimaryClosureAssignmentView(
            code: item.code,
            titleText: item.title,
            phoneText: item.phone,
            currency: Kit.Text.truncate(item.currency, limit: 40),
            acuityText: String(item.acuity),
            amount: String(format: "%.2f", item.amount),
            discount: String(format: "%.2f", item.discount),
            batchSizeText: String(item.batchSize),
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryClosureAssignmentViews(_ items: [PrimaryClosureAssignment]) -> [PrimaryClosureAssignmentView] {
        var views: [PrimaryClosureAssignmentView] = []
        for item in items {
            views.append(toPrimaryClosureAssignmentView(item))
        }
        return views
    }

    static func sumPrimaryClosureAssignmentView(_ view: PrimaryClosureAssignmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedAcuity) + parsedAmount + parsedDiscount
    }
}
