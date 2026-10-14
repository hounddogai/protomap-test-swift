import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default consent form adjustment.
    final class DefaultConsentFormAdjustmentView {
        var code: String
        var titleText: String
        var allergy: String
        var descriptionText: String
        var contactEmail: String
        var amountText: String
        var statusLabel: String

        init(code: String, titleText: String, allergy: String, descriptionText: String, contactEmail: String, amountText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.allergy = allergy
            self.descriptionText = descriptionText
            self.contactEmail = contactEmail
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultConsentFormAdjustmentView(_ item: DefaultConsentFormAdjustment) -> DefaultConsentFormAdjustmentView {
        return DefaultConsentFormAdjustmentView(
            code: item.code,
            titleText: item.title,
            allergy: item.allergy,
            descriptionText: item.description,
            contactEmail: item.contactEmail,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultConsentFormAdjustmentViews(_ items: [DefaultConsentFormAdjustment]) -> [DefaultConsentFormAdjustmentView] {
        var views: [DefaultConsentFormAdjustmentView] = []
        for item in items {
            views.append(toDefaultConsentFormAdjustmentView(item))
        }
        return views
    }

    static func sumDefaultConsentFormAdjustmentView(_ view: DefaultConsentFormAdjustmentView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
